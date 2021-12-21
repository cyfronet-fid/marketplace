# frozen_string_literal: true

class Service::Question::Deliver
  def initialize(service_question)
    @service_question = service_question
    @service = @service_question.service
  end

  def call
    @service.public_contacts.each do |contact|
      ServiceMailer.new_question(
        contact.email,
        @service_question.author,
        @service_question.email,
        @service_question.text,
        @service
      ).deliver_later
    end

    Jms::PublishJob.perform_later(jms_message) if publish_to_jms?
  end

  private

  def publish_to_jms?
    @service.upstream&.eosc_registry?
  end

  def jms_message
    {
      message_type: "service_question",
      timestamp: Time.now.utc.iso8601,
      resource: @service.pid,
      author: @service_question.author,
      email: @service_question.email,
      text: @service_question.text
    }
  end
end
