if defined?(Rails)
  if Rails.version < "3"
    load "tasks/porter.rake"
  else
    module PgbackupsArchive
      class Railtie < Rails::Railtie
        rake_tasks do
          load "tasks/porter.rake"
        end
      end
    end
  end
end
