define_porter_tasks = Proc.new do

  namespace :porter do

    task :db do
      set :user, ENV["AS"] || ENV["USER"]

      database_yml = ""
      run "cat #{deploy_to}/current/config/database.yml" do |channel, stream, data|
        database_yml << data
      end

      config   = YAML::load(database_yml)[stage.to_s]
      database = config["database"]
      username = config["username"]
      password = config["password"]

      run "mysqldump --user=#{username} --password=#{password} #{database} | gzip > ~/#{database}.sql.gz"
      system "rake porter:#{stage}:db"
    end

  end

end

require "capistrano"
instance = Capistrano::Configuration.instance

if instance
  instance.load &define_porter_tasks
else
  define_porter_tasks.call
end
