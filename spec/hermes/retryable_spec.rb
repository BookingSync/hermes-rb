RSpec.describe Hermes::Retryable do
  describe "#perform" do
    subject(:retryable) { described_class.new(times: 3, errors: errors) }
    subject(:retryable_with_before_retry) { described_class.new(times: 3, errors: errors, before_retry: before_retry) }

    let(:errors) { [NotImplementedError] }
    let(:before_retry) do
      Class.new do
        attr_reader :called, :errors

        def initialize
          @called = 0
          @errors = []
        end

        def call(error)
          @called += 1
          @errors << error
        end
      end.new
    end

    it "retries logic for given amount of times for given errors
    and raises original error if the number is exceeded" do
      times_executed = 0

      expect {
        retryable.perform do
          times_executed += 1
          raise NotImplementedError
        end
      }.to raise_error NotImplementedError

      expect(times_executed).to eq 3
    end

    it "calls before_retry callback before every retry" do
      expect {
        retryable_with_before_retry.perform do
          raise NotImplementedError
        end
      }.to raise_error NotImplementedError

      expect(before_retry.called).to eq 2
      expect(before_retry.errors.count).to eq 2
      expect(before_retry.errors.uniq.first).to be_a NotImplementedError
    end

    it "does not retry for given amount of times if it succeeds before exceeding given number" do
      times_executed = 0

      retryable.perform do
        times_executed += 1
        raise NotImplementedError if times_executed < 2
      end

      expect(times_executed).to eq 2
    end

    it "does not retry if no error is raised" do
      times_executed = 0

      retryable.perform do
        times_executed += 1
      end

      expect(times_executed).to eq 1
    end

    context "for non-whitelisted error" do
      let(:errors) { [LocalJumpError] }

      it "does not retry not whitelisted errors" do
        times_executed = 0

        expect {
          retryable.perform do
            times_executed += 1
            raise NotImplementedError
          end
        }.to raise_error NotImplementedError

        expect(times_executed).to eq 1
      end
    end
  end
end
