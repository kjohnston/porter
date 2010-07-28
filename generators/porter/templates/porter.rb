$VERBOSE = nil
if porter = Gem.searcher.find('porter')
  Dir["#{porter.full_gem_path}/lib/tasks/*.rake"].each { |ext| load ext }
end