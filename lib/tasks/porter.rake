config = YAML::load_file(Rails.root.join('config', 'porter_config.yml'))
stages = config.keys
stage  = ARGV[0]

namespace :porter do
  stages.each do |stage|
    namespace stage do
      task :db => :environment do
        src_db     = ActiveRecord::Base.configurations[Rails.env]["database"].split("_").first+"_"+stage
        src_user   = config[stage]["user"]

        src_domain = config[stage]["domain"]

        dest_db    = ActiveRecord::Base.configurations[Rails.env]
        dest_root  = Rails.root
        app        = src_db.split('_').first
        root       = Rails.root

        puts "Retrieving latest compressed database backup from #{stage} server..."
        system "scp #{src_user}@#{src_domain}:~/#{src_db}.sql.gz #{root}"

        puts "Decompressing database backup..."
        system "gunzip #{root}/#{src_db}.sql.gz"

        # Drop the database if it exists
        begin
          ActiveRecord::Base.establish_connection(dest_db)
          ActiveRecord::Base.connection # Should raise Mysql::Error if db doesn't exist
          puts "Dropping database: " + dest_db['database']
          Rake::Task['db:drop'].execute
        rescue Mysql2::Error => e
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
        cmd << "< #{root}/#{src_db}.sql"
        system cmd.join(' ') # Run the mysql import

        puts "Removing database backup file..."
        system "rm #{root}/#{src_db}.sql"

        puts "Database reload complete"
      end

      task :assets => :environment do
        root           = Rails.root
        user           = config[stage]['user']
        domain         = config[stage]['domain']
        app_dir        = config[stage]['app_dir']
        asset_dirs     = config[stage]['asset_dirs'].blank? ? '' : config[stage]['asset_dirs'].gsub(/,/,'').split(' ').map { |i| i.strip }
        rsync_options  = config[stage]['rsync_options']

        asset_dirs.each do |d|
          puts "Synchronizing assets in #{d}..."
          system "rsync #{rsync_options} #{user}@#{domain}:#{app_dir}/#{d}/ #{d}"
        end

        puts "Asset synchronization complete"
      end
    end
  end
end