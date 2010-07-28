$VERBOSE = nil
Dir["#{Gem.searcher.find('porter').full_gem_path}/lib/tasks/*.rake"].each { |ext| load ext }