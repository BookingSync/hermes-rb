require "hutch"
require "timecop"
require "vcr"
require "dry/struct"
require "hermes-rb"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:example, :freeze_time) do |example|
    Timecop.freeze(Time.now.round) { example.run }
  end

  config.after(:each) do
    Hermes::Publisher.instance.reset
  end

  module Types
    include Dry.Types()
  end
end
