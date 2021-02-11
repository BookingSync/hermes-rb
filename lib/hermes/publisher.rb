require "forwardable"
require "singleton"

module Hermes
  class Publisher
    include Singleton
    extend Forwardable

    attr_reader :configuration, :mutex
    private     :configuration, :mutex

    def_delegators :current_adapter, :publish

    def initialize(configuration: Hermes::DependenciesContainer["config"])
      super()
      @configuration = configuration
      @mutex = Mutex.new
    end

    def reset
      self.current_adapter = nil
    end

    def current_adapter=(adapter)
      mutex.synchronize do
        @current_adapter = adapter
      end
    end

    def current_adapter
      mutex.synchronize do
        @current_adapter ||= begin
          Hermes::PublisherFactory.build(configuration.adapter)
        end
      end
    end
  end
end
