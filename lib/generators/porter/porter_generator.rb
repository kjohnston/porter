require 'rails/generators'

class PorterGenerator < Rails::Generators::Base

  attr_accessor :app, :domain

  def self.source_root
    @source_root ||= File.join(File.dirname(__FILE__), 'templates')
  end

  def create_config_file
    @app    = Rails.root.to_s.split('/').last
    @domain = @app + (@app.include?('.') ? '' : '.com')

    template 'porter_config.yml', 'config/porter_config.yml'
    readme 'INSTALL'
  end

end
