module Hermes
  class Logger
    class ParamsFilter
      SENSITIVE_ATTRIBUTES_KEYWORDS = %w(token password credit_card card_number security_code verification_value
        private_key signature api_key secret_key publishable_key client_key client_secret secret).freeze
      STRIPPED_VALUE = "[STRIPPED]".freeze

      private_constant :SENSITIVE_ATTRIBUTES_KEYWORDS, :STRIPPED_VALUE

      attr_reader :sensitive_keywords, :stripped_value
      private     :sensitive_keywords, :stripped_value

      def initialize(sensitive_keywords: SENSITIVE_ATTRIBUTES_KEYWORDS, stripped_value: STRIPPED_VALUE)
        @sensitive_keywords = sensitive_keywords.map(&:to_s)
        @stripped_value = stripped_value
      end

      def call(attribute, value)
        if sensitive_keywords.any? { |sensitive_attribute| attribute.to_s.downcase.match(sensitive_attribute.to_s.downcase) } && value.respond_to?(:to_str)
          value.gsub!(value, stripped_value)
        end
      end
    end
  end
end
