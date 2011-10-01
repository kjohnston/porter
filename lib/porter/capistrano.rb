require "capistrano"

if instance = Capistrano::Configuration.instance
  instance.load do

    namespace :porter do

      task :db do
        set :user, ENV["AS"] || ENV["USER"]
        puts "Connecting to #{domain} as #{user}..."

        puts "Reading database.yml on #{domain}..."
        database_yml = ""
        run "cat #{deploy_to}/current/config/database.yml" do |channel, stream, data|
          database_yml << data
        end

        config   = YAML::load(database_yml)[stage.to_s]
        database = config["database"]
        username = config["username"]
        password = config["password"]

        puts "Creating compressed backup of #{database} database on #{domain}..."
        run "mysqldump --user=#{username} --password=#{password} #{database} | gzip > ~/#{database}.sql.gz"

        system "rake porter:db DOMAIN=#{domain} DATABASE=#{database}"
      end

      task :assets do
        set :user, ENV["AS"] || ENV["USER"]
        system "rake porter:assets STAGE=#{stage.to_s} DOMAIN=#{domain} APP_DIR=#{deploy_to}"
      end

    end

  end
end
