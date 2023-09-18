# frozen_string_literal: true

module Publishable
  extend ActiveSupport::Concern

  included do
    after_create :send_to_databus_create
    after_update :send_to_databus_update
    after_destroy :send_to_databus_destroy

    private

    %i[create update destroy].each do |type|
      define_method "send_to_databus_#{type}" do
        publish(payload_for(type))
      end
    end

    def publish(payload)
      Jms::PublishJob.perform_later(payload, :mp_db_events)
    end

    def payload_for(cud_type)
      { cud: cud_type, model: self.class.name, record: serialize_for_databus, timestamp: Time.current.iso8601 }.as_json
    end

    def serialize_for_databus
      serializer = "Recommender::#{self.class}Serializer".constantize
      serializer.new(self).as_json
    end
  end
end
