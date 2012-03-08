# Porter Gem

The Porter gem is comprised of Capistrano and Rake tasks that make cloning remote server data down to your local Rails application environment a cinch.

## Dependencies

* Capistrano and a proper Capistrano Multistage configuration
* Rake
* A Rails app
* rsync (locally and remotely, if you want to sync assets)

## Capistrano Multistage (capistrano-ext)

As of v1.1.0, Porter expects that your Capistrano setup utilizes the Capistrano Multistage Extension (capistrano-ext).  This is a really great way to manage the various "stages" you deploy to and Porter is opinionated in that it requires you to organize your stage-specific settings into the Capistrano Multistage pattern.

More on the Capistrano Multistage Extension:
[https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension](https://github.com/capistrano/capistrano/wiki/2.x-Multistage-Extension)

## Installation

* Add gem "porter", "~> 1.2.0" to your Gemfile
* Run: bundle install
* Run: rails g porter
* Add require "porter/capistrano" to your config/deploy.rb
* Review the generated config/porter_config.yml (just so you're familiar, it's pretty straight-forward)

## Usage

### Purge your local database and reload data from a remote server's MySQL dump

    $  bundle exec cap production porter:db

This will do the following:

* A mysqldump command will be remotely issued (via Capistrano) to the remote server, saving the result as a compressed (gz) file
* The database backup file from the server will be retrieved (via scp) and decompressed
* The database for the environment you are running the task in will be dropped, recreated, the schema will be reloaded from schema.rb and the mysqldump will be restored

Note: Since the schema is reloaded once the database is recreated, but before the backup is restored, you should end up with tables that match the remote stage, except for the tables you configure to ignore during the backup - which will be provisioned from your local schema.rb's definition.

#### Optionally omit specific tables from the MySQL dump

Using the ignore_tables attribute in the porter_config.yml file, you can specify any number of tables to ignore in the mysqldump that is executed on the remote server.  This setting is available for each stage (server) you define in the config file.  Table names should be separated by spaces.

You can override the ignore_tables setting as needed when executing the porter:db task with an environment variable:

    $  bundle exec cap production porter:db IGNORE_TABLES="delayed_jobs versions"

### Synchronize a remote server's filesystem-stored assets to your local filesystem

    $  bundle exec cap production porter:assets

This will do the following:

* Assets stored in directories you define will be rysnc'd down to your local application directory

## License

The MIT License

Copyright (c) 2010-2012 Kenny Johnston

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
