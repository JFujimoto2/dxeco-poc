require "rails_helper"

RSpec.describe ErrorSubscriber do
  include ActiveSupport::Testing::TimeHelpers

  let(:error) { StandardError.new("something went wrong") }
  let(:context) { {} }

  before do
    stub_const("TeamsNotifier::ERROR_WEBHOOK_URL", "https://example.com/webhook")
    allow(TeamsNotifier).to receive(:notify_error)
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rails.cache = @original_cache
  end

  describe "#report" do
    it "notifies Teams with error details" do
      subscriber = described_class.new
      subscriber.report(error, handled: false, severity: :error, context: context)

      expect(TeamsNotifier).to have_received(:notify_error).with(
        error: error,
        context: context
      )
    end

    it "skips notification for handled errors" do
      subscriber = described_class.new
      subscriber.report(error, handled: true, severity: :warning, context: context)

      expect(TeamsNotifier).not_to have_received(:notify_error)
    end

    it "skips notification for non-error severity" do
      subscriber = described_class.new
      subscriber.report(error, handled: false, severity: :warning, context: context)

      expect(TeamsNotifier).not_to have_received(:notify_error)
    end

    it "throttles duplicate errors within 5 minutes" do
      subscriber = described_class.new
      subscriber.report(error, handled: false, severity: :error, context: context)
      subscriber.report(error, handled: false, severity: :error, context: context)

      expect(TeamsNotifier).to have_received(:notify_error).once
    end

    it "allows same error after throttle period expires" do
      subscriber = described_class.new
      subscriber.report(error, handled: false, severity: :error, context: context)

      travel 6.minutes do
        subscriber.report(error, handled: false, severity: :error, context: context)
      end

      expect(TeamsNotifier).to have_received(:notify_error).twice
    end

    it "allows different errors within throttle period" do
      subscriber = described_class.new
      other_error = RuntimeError.new("different error")

      subscriber.report(error, handled: false, severity: :error, context: context)
      subscriber.report(other_error, handled: false, severity: :error, context: context)

      expect(TeamsNotifier).to have_received(:notify_error).twice
    end
  end
end
