if defined?(Capistrano::Configuration)
  Capistrano::Configuration.instance.load do
    namespace :porter do
      CONFIG    = YAML::load_file('config/porter_config.yml')
      DATABASES = YAML::load_file('config/database.yml')
      STAGES    = DATABASES.keys - %w(development test) # you don't need data out of these
      STAGES.each do |stage|
        # task names for each of your other stages: production, staging, etc.
        # cap porter:production, cap porter:staging, etc.
        task stage do
          src_db = DATABASES[stage]
          db     = src_db['database']
          user   = src_db['username']
          pass   = src_db['password']

          domain = CONFIG[stage].nil? ? CONFIG['server']['domain'] : CONFIG[stage]['domain']
          server domain, :porter

          run "mysqldump --user=#{user} --password=#{pass} #{db} | gzip > ~/#{db}.sql.gz", :roles => :porter
          system "rake porter:#{stage}:db"
          system "rake porter:#{stage}:assets"
        end
      end
    end
  end
end
