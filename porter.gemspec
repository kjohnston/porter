# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{porter}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kenny Johnston"]
  s.date = %q{2010-06-17}
  s.description = %q{Capistrano and Rake tasks for cloning production database and assets to development.}
  s.email = %q{info@appcreations.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "generators/porter/lib/insert_commands.rb",
     "generators/porter/porter_generator.rb",
     "generators/porter/templates/porter.rake",
     "generators/porter/templates/porter_config.yml",
     "lib/porter.rb",
     "lib/porter/recipes/porter.rb",
     "porter.gemspec",
     "test/helper.rb"
  ]
  s.homepage = %q{http://github.com/kjohnston/porter}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Capistrano and Rake tasks for cloning production database and assets to development.}
  s.test_files = [
    "test/helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<capistrano>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<capistrano>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<capistrano>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end

