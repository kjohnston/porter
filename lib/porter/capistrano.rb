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
        db_config   = YAML::load(db_yml)[stage.to_s]
        db_name     = db_config["database"]
        db_username = db_config["username"]
        db_password = db_config["password"]

        puts "Creating compressed backup of #{db_name} database on #{domain}..."
        run "mysqldump --user=#{db_username} --password=#{db_password} #{db_name} | gzip > ~/#{db_name}.sql.gz"

        system "rake porter:db DOMAIN=#{domain} DATABASE=#{db_name}"
      end

      task :assets do
        system "rake porter:assets STAGE=#{stage.to_s} DOMAIN=#{domain} APP_DIR=#{deploy_to}"
      end

    end

  end
end
