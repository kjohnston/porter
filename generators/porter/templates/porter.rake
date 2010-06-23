namespace :porter do
  namespace :production do
    task :db => :environment do
      root     = RAILS_ROOT
      config   = YAML.load_file(File.join(RAILS_ROOT, 'config', 'porter_config.yml'))
      user     = config['server']['user']
      domain   = config['server']['domain']
      dbconfig = ActiveRecord::Base.configurations[RAILS_ENV]
      app      = dbconfig['database'].gsub('_dev', '')
    
      puts "Retrieving latest compressed database backup from production server..."
      system "scp #{user}@#{domain}:~/#{app}.sql.gz #{root}"

      puts "Decompressing database backup..."
      system "gunzip #{root}/#{app}.sql.gz"

      # Drop the database if it exists
      begin
        ActiveRecord::Base.establish_connection(dbconfig)
        ActiveRecord::Base.connection # Should raise Mysql::Error if db doesn't exist
        puts "Dropping database: " + dbconfig['database']
        Rake::Task['db:drop'].execute
      rescue Mysql::Error => e
        raise e unless e.message =~ /Unknown database/
      end

      puts "Creating database: " + dbconfig['database']
      Rake::Task['db:create'].execute

      puts "Restoring database from backup..."
      mysql_version = `which mysql`.empty? ? 'mysql5' : 'mysql'
      system "#{mysql_version} -u root #{dbconfig['database']} < #{root}/#{app}.sql"

      puts "Removing database backup file..."
      system "rm #{root}/#{app}.sql"

      puts "Production data reload complete"
    end

    task :assets => :environment do
      require 'yaml'
      root          = RAILS_ROOT
      config        = YAML.load_file(File.join(RAILS_ROOT, 'config', 'porter_config.yml'))
      user          = config['server']['user']
      domain        = config['server']['domain']
      dir           = config['server']['dir']
      model         = config['assets']['model'].constantize
      column        = config['assets']['column']
      exclusions    = config['assets']['exclusions'].blank? ? '' : config['assets']['exclusions'].split(',').map { |i| i.strip }
      rsync_options = config['assets']['rsync_options']

      excluding = exclusions.blank? ? '' : "(excluding: #{config['assets']['exclusions']} files) "
      puts "Building a list of assets #{excluding}to rsync down..."
      
      unless exclusions.blank?
        rsync_file_list = File.new('rsync_file_list.txt', "w")
        attachments = model.find(:all, :conditions => ["#{column} NOT IN (?)", exclusions])
        attachments.each do |a|
          rsync_file_list.send((a == attachments.last ? :print : :puts), ('attachments/' + a.partitioned_path.join('/')))
        end
        rsync_file_list.close
      end
      
      rsync_list_command = exclusions.blank? ? '' : "--files-from=#{root}/rsync_file_list.txt "
    
      puts "Synchronizing with production assets..."
      system "rsync #{rsync_list_command}#{rsync_options} --exclude 'plugin_assets' #{user}@#{domain}:#{dir}/shared/public/ public"

      system "rm #{root}/rsync_file_list.txt" if File.exists?("#{root}/rsync_file_list.txt")

      puts "Production asset synchronization complete"
    end
  end
end