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

  config.run_all_when_everything_filtered = true
  config.filter_run focus: true

  config.mock_with :rspec

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.around(:example, :freeze_time) do |example|
    Timecop.freeze(Time.now.round) { example.run }
  end

  config.around(:example, :with_application_prefix) do |example|
    original_application_prefix = Hermes.configuration

    Hermes.configure do |config|
      config.application_prefix = "app_prefix"
    end

    example.run

    Hermes.configure do |config|
      config.application_prefix = original_application_prefix
    end
  end

  config.after(:each) do
    Hermes::Publisher.instance.reset
  end

  config.before(:example, :with_hutch_worker) do
    @worker_thread = Thread.new do
      Hutch.connect
      worker = Hutch::Worker.new(Hutch.broker, Hutch.consumers, Hutch::Config.setup_procs)
      worker.run
    end

    sleep 0.2
  end

  config.after(:example, :with_hutch_worker) do
    @worker_thread.kill
  end

  config.after(:example) do
    Hermes.origin_headers = {}
  end

  ENV["DATABASE_URL"] ||= "postgresql://localhost/hermes-rb-test"
  ENV["DISTRIBUTED_TRACING_DATABASE_URI"] ||= ENV["DATABASE_URI"]

  if Gem::Version.new(ActiveRecord::VERSION::STRING) > Gem::Version.new('6')
    # Rails 5.2 is unable to handle this
    ActiveRecord::Tasks::DatabaseTasks.create(ENV["DATABASE_URL"])
  end

  ActiveRecord::Base.establish_connection(ENV["DATABASE_URL"])

  ActiveRecord::Schema.define do
    drop_table(:hermes_distributed_traces, if_exists: true)
    create_table(:hermes_distributed_traces) do |t|
      t.string "trace", null: false
      t.string "span", null: false
      t.string "parent_span"
      t.string "service", null: false
      t.text "event_class", null: false
      t.text "routing_key", null: false
      t.jsonb "event_body", null: false, default: []
      t.jsonb "event_headers", null: false, default: []
      t.datetime "created_at", precision: 6, null: false
      t.datetime "updated_at", precision: 6, null: false

      t.index ["created_at"], name: "index_hermes_distributed_traces_on_created_at", using: :brin
      t.index ["trace"], name: "index_hermes_distributed_traces_on_trace"
      t.index ["span"], name: "index_hermes_distributed_traces_on_span"
      t.index ["service"], name: "index_hermes_distributed_traces_on_service"
      t.index ["event_class"], name: "index_hermes_distributed_traces_on_event_class"
      t.index ["routing_key"], name: "index_hermes_distributed_traces_on_routing_key"
    end
  end

  config.before(:each) do
    Hermes::DistributedTrace.delete_all
  end

  config.after(:each) do
    Hermes::DistributedTrace.delete_all
  end

  module Types
    include Dry.Types()
  end

  RSpec::Matchers.define_negated_matcher :avoid_changing, :change
end
