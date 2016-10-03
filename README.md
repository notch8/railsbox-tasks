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
`rake %ENV% railsbox:deploy` Deploys the app. Development does not need to be deployed to use
`rake %ENV% railsbox:provision` Provisions the app.

Where %ENV% is development / staging / production. 

### Postgres
`rake %ENV% railsbox:pg:pull_db_from_heroku` Pull a postgres database from Heroku, drops your local development database, and imports the heroku database into your development database.
`rake %ENV% railsbox:pg:dump` Pulls a database dump from one of your deployed environments and puts the dump in the /tmp directory of your rails app.
`rake %ENV% railsbox:pg:restore` Drops your development database and uses the database dump created by `rake railsbox:pg:pg_dump_download` to repopulate your development database.

### mysql
There are similar commands to those above.
`rake %ENV% railsbox:mysql:dump` Pulls a database dump from one of your deployed environments and puts the dump in the /tmp directory of your rails app.
`rake %ENV% railsbox:mysql:restore` Drops your development database and uses the database dump created by `rake railsbox:pg:pg_dump_download` to repopulate your development database.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/notch8/railsbox. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

