CONFIG    = YAML::load_file(File.join(RAILS_ROOT, 'config', 'porter_config.yml'))
DATABASES = YAML::load_file(File.join(RAILS_ROOT, 'config', 'database.yml'))
STAGES    = DATABASES.keys - %w(development test) # you don't need data out of these

namespace :porter do
  STAGES.each do |stage|
    namespace stage do
      task :db => :environment do
        # Optional: You can setup specific username and host 
        # combos for each stage in porter_config.yml or use
        # the default 'server' key to apply to all stages
        if CONFIG[stage]
          src_user     = CONFIG[stage]['user']
          src_domain   = CONFIG[stage]['domain']
        else
          src_user     = CONFIG['server']['user']
          src_domain   = CONFIG['server']['domain']
        end
          
        src_db    = ActiveRecord::Base.configurations[stage]
        dest_db   = ActiveRecord::Base.configurations[RAILS_ENV]
        dest_root = RAILS_ROOT
        
        app       = src_db['database'].split('_').first
        root      = RAILS_ROOT
    
        puts "Retrieving latest compressed database backup from #{stage} server..."
        system "scp #{src_user}@#{src_domain}:~/#{src_db['database']}.sql.gz #{root}"

        puts "Decompressing database backup..."
        system "gunzip #{root}/#{src_db['database']}.sql.gz"

        # Drop the database if it exists
        begin
          ActiveRecord::Base.establish_connection(dest_db)
          ActiveRecord::Base.connection # Should raise Mysql::Error if db doesn't exist
          puts "Dropping database: " + dest_db['database']
          Rake::Task['db:drop'].execute
        rescue Mysql::Error => e
          raise e unless e.message =~ /Unknown database/
        end

        puts "Creating database: " + dest_db['database']
        Rake::Task['db:create'].execute

        puts "Restoring database from backup..."
        mysql_version = `which mysql`.empty? ? 'mysql5' : 'mysql'
        system "#{mysql_version} -u root #{dest_db['database']} < #{root}/#{src_db['database']}.sql"

        puts "Removing database backup file..."
        system "rm #{root}/#{src_db['database']}.sql"

        puts "Production data reload complete"
      end

      task :assets => :environment do
        root           = RAILS_ROOT
        user           = CONFIG[stage].nil? ? CONFIG['server']['user']   : CONFIG[stage]['user']
        domain         = CONFIG[stage].nil? ? CONFIG['server']['domain'] : CONFIG[stage]['domain']
        dir            = CONFIG[stage].nil? ? CONFIG['server']['dir']    : CONFIG[stage]['dir']
        entire_dirs    = CONFIG['assets']['entire_dirs'].blank? ? '' : CONFIG['assets']['entire_dirs'].gsub(/,/,'').split(' ').map { |i| i.strip }
        excludable_dir = CONFIG['assets']['excludable_dir']
        model          = CONFIG['assets']['excludable_model'].constantize unless CONFIG['assets']['excludable_model'].blank?
        column         = CONFIG['assets']['excludable_column']
        exclusions     = CONFIG['assets']['excludable_matches'].blank? ? '' : CONFIG['assets']['excludable_matches'].gsub(/,/,'').split(' ').map { |i| i.strip }
        rsync_options  = CONFIG['assets']['rsync_options']
      
        if exclusions.blank?
          entire_dirs << excludable_dir unless excludable_dir.blank?
        else
          puts "Building a list of excludable assets (excluding: #{exclusions.join(', ')}) to rsync down..."
          rsync_file_list = File.new('rsync_file_list.txt', "w")
          attachments = model.find(:all, :conditions => ["#{column} NOT IN (?)", exclusions])
          attachments.each do |a|
            rsync_file_list.send((a == attachments.last ? :print : :puts), a.partitioned_path.join('/'))
          end
          rsync_file_list.close
          system "rsync --files-from=#{root}/rsync_file_list.txt #{rsync_options} #{user}@#{domain}:#{dir}/shared/#{excludable_dir}/ #{excludable_dir}"
          system "rm #{root}/rsync_file_list.txt" if File.exists?("#{root}/rsync_file_list.txt")
        end
      
        entire_dirs.each do |d|
          puts "Synchronizing assets in #{d}..."
          system "rsync #{rsync_options} #{user}@#{domain}:#{dir}/shared/#{d}/ #{d}"
        end

        puts "Production asset synchronization complete"
      end
    end
  end
end