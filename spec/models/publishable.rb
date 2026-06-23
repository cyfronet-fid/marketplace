# frozen_string_literal: true

shared_examples "publishable" do
  context "publishable integration tests" do
    before(:each) do
      travel_to Time.zone.local(1997, 3, 9)
      clear_enqueued_jobs
    end

    after(:each) do
      travel_back
      clear_enqueued_jobs
    end

    it "should enqueue JMS job after create" do
      expect { create(factory_name) }.to have_enqueued_job(Jms::PublishJob).with(
        hash_including("record", "cud" => "create", "model" => described_class.name, "timestamp" => expected_timestamp),
        :mp_db_events
      )
    end

    it "should enqueue JMS job after update" do
      obj = create(factory_name)
      clear_enqueued_jobs

      # best approximation of field that exists on almost all models
      field_name_to_update = obj.attributes.keys.include?("name") ? :name : :first_name

      obj.send("#{field_name_to_update}=", "new value")

      expect { obj.save }.to have_enqueued_job(Jms::PublishJob).with(
        hash_including("record", "cud" => "update", "model" => described_class.name, "timestamp" => expected_timestamp),
        :mp_db_events
      )
    end

    it "should enqueue JMS job after destroy" do
      obj = create(factory_name)
      clear_enqueued_jobs

      expect { obj.destroy }.to have_enqueued_job(Jms::PublishJob).with(
        hash_including(
          "record",
          "cud" => "destroy",
          "model" => described_class.name,
          "timestamp" => expected_timestamp
        ),
        :mp_db_events
      )
    end

    def factory_name
      described_class.name.underscore.to_sym
    end

    def expected_timestamp
      Time.current.iso8601
    end
  end
end
