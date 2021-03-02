require_relative 'lib/hermes/rb/version'

Gem::Specification.new do |spec|
  spec.name          = "hermes-rb"
  spec.version       = Hermes::Rb::VERSION
  spec.authors       = ["Karol Galanciak"]
  spec.email         = ["dev@bookingsync.com"]

  spec.summary       = %q{A messenger of gods, delivering them via RabbitMQ with a little help from Hutch}
  spec.description   = %q{A messenger of gods, delivering them via RabbitMQ with a little help from Hutch}
  spec.homepage      = "https://github.com/BookingSync/hermes-rb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BookingSync/hermes-rb"
  spec.metadata["changelog_uri"] = "https://github.com/BookingSync/hermes-rb/Changelog.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-struct", "~> 1"
  spec.add_dependency "dry-container", "~> 0"
  spec.add_dependency "hutch", "~> 1.0"
  spec.add_dependency "activesupport", ">= 5"
  spec.add_dependency "activerecord", ">= 5"
  spec.add_dependency "request_store", "~> 1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "newrelic_rpm"
  spec.add_development_dependency "ddtrace"
end
