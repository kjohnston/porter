CONFIG    = YAML::load_file(Rails.root.join('config', 'porter_config.yml'))
DATABASES = YAML::load_file(Rails.root.join('config', 'database.yml'))
STAGES    = DATABASES.keys - %w(development test) # you don't need data out of these

namespace :porter do
  STAGES.each do |stage|
    namespace stage do
      task :db => :environment do
        if CONFIG[stage]
          src_user     = CONFIG[stage]['user']
          src_domain   = CONFIG[stage]['domain']
        else
          puts "Please tell config/porter_config.yml about the '#{stage}' server."
          return
        end
          
        src_db    = ActiveRecord::Base.configurations[stage]
        dest_db   = ActiveRecord::Base.configurations[Rails.env]
        dest_root = Rails.root
        
        app       = src_db['database'].split('_').first
        root      = Rails.root
    
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
        cmd = [mysql_version]
        cmd << "-u #{dest_db['username']}"
        cmd << "--password=#{dest_db['password']}" unless dest_db['password'].blank?
        cmd << dest_db['database']
        cmd << "< #{root}/#{src_db['database']}.sql"
        system cmd.join(' ') # Run the mysql import

        puts "Removing database backup file..."
        system "rm #{root}/#{src_db['database']}.sql"

        puts "Database reload complete"
      end

      task :assets => :environment do
        root           = Rails.root
        user           = CONFIG[stage]['user']
        domain         = CONFIG[stage]['domain']
        app_dir        = CONFIG[stage]['app_dir']
        asset_dirs     = CONFIG[stage]['asset_dirs'].blank? ? '' : CONFIG[stage]['asset_dirs'].gsub(/,/,'').split(' ').map { |i| i.strip }
        rsync_options  = CONFIG[stage]['rsync_options']
      
        asset_dirs.each do |d|
          puts "Synchronizing assets in #{d}..."
          system "rsync #{rsync_options} #{user}@#{domain}:#{app_dir}/#{d}/ #{d}"
        end

        puts "Asset synchronization complete"
      end
    end
  end
end