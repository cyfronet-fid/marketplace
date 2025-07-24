# frozen_string_literal: true

shared_examples "publishable" do
  context "publishable integration tests" do
    before(:each) do
      stomp_config = Mp::Application.config_for(:stomp_subscriber)
      @client = Stomp::Client.new(stomp_config["login"], stomp_config["password"], stomp_config["host"])
      @received = []

      @client.subscribe("/topic/#{stomp_config["mp-db-events-destination"]}") do |msg|
        @received << JSON.parse(msg.body)
      end
      # mock the Time.now call for consistency
      allow(Time).to receive(:current).and_return(Time.new(1997, 3, 9))
    end

    after(:each) { clear_enqueued_jobs }

    after(:all) { @client&.close }

    it "should enqueue JMS job after create", retry: 5, retry_wait: 5 do
      perform_enqueued_jobs { create(described_class.name.underscore.to_sym) }

      # Sadly there's no way to synchronously wait for messages
      # (At least in the "stomp" gem which we're using)
      # So I'm just waiting 1 second here and then check for received messages
      #
      # Since the active MQ should be run on the same host as the test
      # I'm expecting the message to be able to be received during that time
      @client.join(2)
      Timeout.timeout(5) { sleep 0.1 until @received.size.positive? }
      expect(@received).to include(
        hash_including(
          "record",
          "cud" => "create",
          "model" => described_class.name,
          "timestamp" => Time.new(1997, 3, 9).iso8601
        )
      )
    end

    it "should enqueue JMS job after update" do
      obj = create(described_class.name.underscore.to_sym)

      # best approximation of field that exists on almost all models
      field_name_to_update = obj.attributes.keys.include?("name") ? :name : :first_name

      obj.send("#{field_name_to_update}=", "new value")

      perform_enqueued_jobs { obj.save }

      # Check comment about this "wait" above
      @client.join(1)
      expect(@received).to include(
        hash_including(
          "record",
          "cud" => "update",
          "model" => described_class.name,
          "timestamp" => Time.new(1997, 3, 9).iso8601
        )
      )
    end

    it "should enqueue JMS job after destroy", :need_queue do
      obj = create(described_class.name.underscore.to_sym)

      perform_enqueued_jobs { obj.destroy }

      # Check comment about this "wait" above
      @client.join(1)
      expect(@received).to include(
        hash_including(
          "record",
          "cud" => "destroy",
          "model" => described_class.name,
          "timestamp" => Time.new(1997, 3, 9).iso8601
        )
      )
    end
  end
end
