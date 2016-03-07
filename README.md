# Railsbox

This gem provides some rake tasks to make working with railsbox and ansible easier.  There are rake tasks to run the different deploys and pull databases from other environments to your development environment.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'railsbox'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install railsbox

## Usage
### Ansible
`rake railsbox:deploy` Deploys the app to whichever environment is set in RAILS_ENV.
`rake railsbox:provision` Provisions the app to whichever environment is set in RAILS_ENV.
### Postgres
`rake railsbox:pg:pull_db_from_heroku` Pull a postgres database from Heroku, drops your local development database, and imports the heroku database into your development database.
`rake railsbox:pg:pg_dump_download` Pulls a database dump from one of your deployed environments and puts the dump in the /tmp directory of your rails app.
`rake railsbox:pg:import_dump_into_dev_pg_db` Drops your development database and uses the database dump created by `rake railsbox:pg:pg_dump_download` to repopulate your development database.
`rake railsbox:pg:pull_dump_and_import` Runs `rake railsbox:pg:pg_dump_download` and `rake railsbox:pg:import_dump_into_dev_pg_db` in series to pull and import data and schema from a deployed app into your development database.
### mysql
There are similar commands to those above but they are not well tested.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/notch8/railsbox. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

