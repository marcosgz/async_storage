# frozen_string_literal: true

require_relative 'lib/async_storage/version'

Gem::Specification.new do |spec|
  spec.name          = 'async_storage'
  spec.version       = AsyncStorage::VERSION
  spec.authors       = ['Marcos G. Zimmermann']
  spec.email         = ['mgzmaster@gmail.com']

  spec.summary       = 'Asynchronous key-value storage system'
  spec.description   = 'Asynchronous key-value storage system'
  spec.homepage      = 'https://github.com/marcosgz/async_storage'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/marcosgz/async_storage'
  spec.metadata['changelog_uri'] = 'https://github.com/marcosgz/async_storage/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'redis', '> 0.0.0'
  spec.add_dependency 'multi_json', '> 0.0.0'
end
