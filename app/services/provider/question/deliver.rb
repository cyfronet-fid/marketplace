# frozen_string_literal: true

class Provider::Question::Deliver
  def initialize(provider_question)
    @provider_question = provider_question
    @provider = @provider_question.provider
  end

  def call
    @provider.public_contacts.each do |contact|
      ProviderMailer.new_question(
        contact.email,
        @provider_question.author,
        @provider_question.email,
        @provider_question.text,
        @provider
      ).deliver_later
    end

    Jms::PublishJob.perform_later(jms_message) if publish_to_jms?
  end

  private

  def publish_to_jms?
    @provider.upstream&.eosc_registry?
  end

  def jms_message
    {
      message_type: "provider_question",
      timestamp: Time.now.utc.iso8601,
      provider: @provider.pid,
      author: @provider_question.author,
      email: @provider_question.email,
      text: @provider_question.text
    }
  end
end
