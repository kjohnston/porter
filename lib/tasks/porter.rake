namespace :porter do

  task :db => :environment do
    domain          = ENV["DOMAIN"]
    user            = ENV["AS"] || ENV["USER"]
    source_database = ENV["DATABASE"]

    destintation_database_config   = ActiveRecord::Base.configurations[Rails.env]
    destintation_database          = destintation_database_config["database"]
    destintation_database_username = destintation_database_config["username"]
    destintation_database_password = destintation_database_config["password"]

    root = Rails.root

    puts "Connecting to #{domain} as #{user}..."

    puts "Retrieving database backup from #{domain}..."
    system "scp #{user}@#{domain}:~/#{source_database}.sql.gz #{root}"

    puts "Decompressing database backup..."
    system "gunzip #{root}/#{source_database}.sql.gz"

    # Drop the database if it exists
    begin
      ActiveRecord::Base.establish_connection(destintation_database_config)
      ActiveRecord::Base.connection # Should raise Mysql::Error if db doesn't exist
      puts "Dropping database: " + destintation_database
      Rake::Task["db:drop"].execute
    rescue Mysql2::Error => e
      raise e unless e.message =~ /Unknown database/
    end

    puts "Creating database: " + destintation_database
    Rake::Task["db:create"].execute

    puts "Loading schema..."
    Rake::Task["db:schema:load"].execute
    rm "#{root}/porter_schema.rb"

    puts "Restoring database from backup..."
    mysql_version = `which mysql`.empty? ? "mysql5" : "mysql"
    cmd = [mysql_version]
    cmd << "-u #{destintation_database_username}"
    cmd << "--password=#{destintation_database_password}" unless destintation_database_password.blank?
    cmd << destintation_database
    cmd << "< #{root}/#{source_database}.sql"
    system cmd.join(' ') # Run the mysql import

    puts "Removing database backup file..."
    system "rm #{root}/#{source_database}.sql"

    puts "Database reload complete"
  end

  task :assets => :environment do
    stage         = ENV["STAGE"]
    domain        = ENV["DOMAIN"]
    user          = ENV["AS"] || ENV["USER"]
    app_dir       = ENV["APP_DIR"]+"/current"
    config        = YAML::load_file(Rails.root.join("config", "porter_config.yml"))
    rsync_options = config[stage]["rsync_options"]

    unless config[stage]["asset_dirs"].blank?
      asset_dirs = config[stage]["asset_dirs"].gsub(/,/,' ').split(' ').map { |i| i.strip }

      puts "Connecting to #{domain} as #{user}..."

      asset_dirs.each do |d|
        puts "Synchronizing assets in #{d}..."
        system "rsync #{rsync_options} #{user}@#{domain}:#{app_dir}/#{d}/ #{d}"
      end
    end

    puts "Asset synchronization complete"
  end

end
