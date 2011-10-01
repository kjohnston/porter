require "porter"
require "rails"

module Porter
  class Railtie < Rails::Railtie
    railtie_name :porter

    rake_tasks do
      load "tasks/porter.rake"
    end
  end
end
