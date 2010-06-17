if defined?(Capistrano)
  Capistrano::Configuration.instance.load do
    namespace :porter do
      task :production do
        require 'yaml'
        config = YAML::load_file('config/database.yml')['production']
        db     = config['database']
        user   = config['username']
        pass   = config['password']
        run "mysqldump --user=#{user} --password=#{pass} #{db} | gzip > ~/#{db}.sql.gz"
        system "rake porter:production:db"
        system "rake porter:production:assets"
      end
    end
  end
end