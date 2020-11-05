# AsyncStorage

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/async_storage`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'async_storage'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install async_storage

## Usage

** Idea about the API of this gem. Update accordingly before release it

Define global configurations
```ruby
# Configurations
AsyncStorage.configuration do |config|
  config.backend = AsyncStorage::Backend::Faktory
  config.respository = AsyncStorage::Repository
  config.expires_in = 3_600
end
```

Useful methods to get, set and check data

```ruby
AsyncStorage.get(klass, 'arg')
AsyncStorage.set(klass, 'arg') { value }
AsyncStorage.delete(klass, 'arg')
AsyncStorage.exist?(klass, 'arg')
AsyncStorage.invalidate(klass, 'arg')
```

```ruby
# app/resolvers/user_tweet_resolver.rb
class UserTweetResolver
  def call(user_id)
    # Return JSON reandly object
  end
end

AsyncStorage[UserTweetResolver].get('123') # Return nil if there is no data
AsyncStorage[UserTweetResolver].get!('123') # Await resolve

class UserTweetResolver
  def initialize(access_token:)
    @access_token = access_token
  end

  def call(user_id)
    # Return JSON reandly object
  end
end

AsyncStorage[UserTweetResolver, access_token: '123'].get(9) # Return nil if there is no data
```


```ruby
AsyncStorage::Set.new(UserTweetResolver).get('123)
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/async_storage.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
