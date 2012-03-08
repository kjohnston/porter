require "capistrano"

if instance = Capistrano::Configuration.instance
  instance.load do

    namespace :porter do

      task :db do
        set :user, ENV["AS"] || ENV["USER"]
        puts "Connecting to #{domain} as #{user}..."

        puts "Reading database.yml on #{domain}..."
        db_yml = ""
        run "cat #{deploy_to}/current/config/database.yml" do |channel, stream, data|
          db_yml << data
        end
        db_config      = YAML::load(db_yml)[stage.to_s]
        db_name        = db_config["database"]
        db_username    = db_config["username"]
        db_password    = db_config["password"]
        db_credentials = "--user=#{db_username} --password=#{db_password} "

        puts "Reading schema.rb on #{domain}..."
        schema_rb = ""
        run "cat #{deploy_to}/current/db/schema.rb" do |channel, stream, data|
          schema_rb << data
        end
        schema_file = "porter_schema.rb"
        File.open(schema_file, "w") do |f|
          f.puts schema_rb
        end

        porter_config = YAML::load_file("config/porter_config.yml")

        if ENV["IGNORE_TABLES"]
          tables_to_ignore = ENV["IGNORE_TABLES"].split(" ")
        elsif stage_config = porter_config[stage.to_s] and stage_config["ignore_tables"]
          tables_to_ignore = stage_config["ignore_tables"].split(" ")
        end
        ignore_tables = (tables_to_ignore || []).map { |table_name| "--ignore-table=#{db_name}.#{table_name.strip}" }.join(" ")

        # Run mysqldump on the stage
        puts "Creating compressed backup of #{db_name} database on #{domain}..."
        run "mysqldump #{db_credentials} #{db_name} #{ignore_tables} | gzip > ~/#{db_name}.sql.gz"

        # Issue rake task to restore the database backup
        system "rake porter:db DOMAIN=#{domain} DATABASE=#{db_name} SCHEMA=#{schema_file}"
      end

      task :assets do
        system "rake porter:assets STAGE=#{stage.to_s} DOMAIN=#{domain} APP_DIR=#{deploy_to}"
      end

    end

  end
end
