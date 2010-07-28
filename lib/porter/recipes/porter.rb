if defined?(Capistrano)
  Capistrano::Configuration.instance.load do
    namespace :porter do
      DATABASE_YML = YAML::load_file('config/database.yml')
      STAGES = DATABASE_YML.keys - %w(development test) # you don't need data out of these
      STAGES.each do |stage|
        # task names for each of your other stages: production, staging, etc.
        # cap porter:production, cap porter:staging, etc.
        task stage do
          require 'yaml'
          config = DATABASE_YML[stage]
          db     = config['database']
          user   = config['username']
          pass   = config['password']
          run "mysqldump --user=#{user} --password=#{pass} #{db} | gzip > ~/#{db}.sql.gz"
          system "rake porter:#{stage}:db"
          system "rake porter:#{stage}:assets"
        end
      end
    end
  end
end