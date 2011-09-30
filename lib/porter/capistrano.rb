define_porter_tasks = Proc.new do

  namespace :porter do
    config = YAML::load_file("config/porter_config.yml")
    stage  = ARGV[0]

    task :db do
      set :user, ENV["AS"] || ENV["USER"]

      s = ""
      run "cat #{config[stage]["app_dir"]}/config/database.yml" do |channel, stream, data|
        s << data
      end

      c      = YAML::load(s)[stage]
      db     = c["database"]
      user   = c["username"]
      pass   = c["password"]
      domain = config[stage]["domain"]
      server domain, :porter

      run "mysqldump --user=#{user} --password=#{pass} #{db} | gzip > ~/#{db}.sql.gz", :roles => :porter
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
