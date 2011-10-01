require "rails/generators"

class PorterGenerator < Rails::Generators::Base

  def self.source_root
    @source_root ||= File.join(File.dirname(__FILE__), "templates")
  end

  def create_config_file
    template "porter_config.yml", "config/porter_config.yml"
    readme "INSTALL"
  end

end
