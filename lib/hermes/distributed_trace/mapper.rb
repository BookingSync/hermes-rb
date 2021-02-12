module Hermes
  class DistributedTrace
    class Mapper
      attr_reader :params_filter
      private     :params_filter

      def initialize(params_filter: Hermes::DependenciesContainer["logger_params_filter"])
        @params_filter = params_filter
      end

      def call(attributes)
        attributes.deep_dup.tap do |attributes_copy|
          attributes_copy.each { |key, value| params_filter.call(key, value) }
        end
      end
    end
  end
end
