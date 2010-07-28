require File.expand_path(File.dirname(__FILE__) + "/lib/insert_commands.rb")

class PorterGenerator < Rails::Generator::Base
  
  attr_accessor :app, :domain
  
  def manifest
    @app    = Dir.glob(RAILS_ROOT).to_s.split('/').last
    @domain = @app + (@app.include?('.') ? '' : '.com')
  
    record do |m|
      m.template 'porter_config.yml', File.join('config', 'porter_config.yml')
      m.template 'porter.rb',         File.join('lib', 'tasks', 'porter.rb')
      m.append_to 'config/deploy.rb', "\n\nrequire 'porter'"
      m.append_to 'Rakefile', "\n\nrequire 'tasks/porter'"
    end        
  end

end