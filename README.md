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
  config.namespace = 'async_storage'  # Default to 'async_storage'
  config.expires_in = 3_600           # Default to nil
end
```


Useful methods to get, set and check data

```ruby
# app/resolvers/user_tweets_resolver.rb
class UserTweetsResolver
  def call(user_id)
    # Return JSON friendly object
    { 'user_id' => user_id, 'tweets' => Twitter::API.tweets(user_id).as_json }
  end
end

AsyncStorage[UserTweetResolver].get('123') # Try to retrieve data. If does not exist enqueue a Background Job and return nil
AsyncStorage[UserTweetResolver].get!('123') # Try to retrieve data. If does not exist imediate call the Resolver and return data
AsyncStorage[UserTweetResolver, namespace: current_site.id].get(9) # Create a new Set using site id namepace
AsyncStorage[UserTweetResolver, expires_in: 60].get(9) # Overwrite global expires_in
```

```ruby
class Site
  # site.cache.user_tweets.get(@user.id)
  def cache
    Cache.new(self.slug)
  end

  class Cache
    RESOLVERS = {
      user_tweets: UserTweetsResolver,
    }.freeze

    RESOLVERS.each do |method, resolver|
      define_method method do
        AsyncStorage[resolver, namespace: @namespace]
      end
    end

    def initialize(namespace)
      @namespace = namespace
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/async_storage.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
