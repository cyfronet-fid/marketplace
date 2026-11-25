# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/otel_logging/request_entry"

RSpec.describe OtelLogging::RequestEntry do
  let(:request_entry) { described_class.new }

  describe "#call" do
    subject(:fields) { request_entry.call(data) }

    context "with the lograge data of a request" do
      let(:data) do
        {
          :method => "GET",
          :path => "/services",
          :format => :html,
          :controller => "ServicesController",
          :action => "index",
          :status => 200,
          :duration => 41.37,
          :view => 30.1,
          :db => 5.2,
          "user.id" => 7
        }
      end

      it "gives the method with the OpenTelemetry name" do
        expect(fields["http.request.method"]).to eq("GET")
      end

      it "gives the path with the OpenTelemetry name" do
        expect(fields["url.path"]).to eq("/services")
      end

      it "gives the status with the OpenTelemetry name" do
        expect(fields["http.response.status_code"]).to eq(200)
      end

      it "gives the duration in milliseconds" do
        expect(fields["duration_ms"]).to eq(41.37)
      end

      it "gives the user id" do
        expect(fields["user.id"]).to eq(7)
      end

      it "gives the method, the path and the status as the body" do
        expect(fields["body"]).to eq("GET /services 200")
      end

      it "gives no other lograge fields" do
        expect(fields.keys).to match_array(
          %w[http.request.method url.path http.response.status_code duration_ms user.id body]
        )
      end
    end

    context "with the lograge data of a request without a user" do
      let(:data) { { :method => "GET", :path => "/services", :status => 200, :duration => 41.37, "user.id" => nil } }

      it "gives no user id" do
        expect(fields).not_to have_key("user.id")
      end
    end

    context "with the lograge data of a failed request" do
      let(:data) do
        {
          :method => "POST",
          :path => "/projects",
          :status => 500,
          :error => "RuntimeError: boom",
          :duration => 12.5,
          "exception.type" => "RuntimeError",
          "exception.message" => "boom"
        }
      end

      it "gives the class of the exception" do
        expect(fields["exception.type"]).to eq("RuntimeError")
      end

      it "gives the message of the exception" do
        expect(fields["exception.message"]).to eq("boom")
      end

      it "gives the status in the body" do
        expect(fields["body"]).to eq("POST /projects 500")
      end

      it "gives no lograge error field" do
        expect(fields).not_to have_key("error")
      end
    end
  end

  describe "#event_fields" do
    subject(:fields) { request_entry.event_fields(event) }

    let(:event) { ActiveSupport::Notifications::Event.new("process_action.action_controller", nil, nil, "1", payload) }

    context "with an event of a failed request" do
      let(:payload) { { exception: %w[RuntimeError boom] } }

      it { is_expected.to eq("exception.type" => "RuntimeError", "exception.message" => "boom") }
    end

    context "with an event of a request without an exception" do
      let(:payload) { { status: 200 } }

      it { is_expected.to eq("exception.type" => nil, "exception.message" => nil) }
    end
  end

  describe "#controller_fields" do
    subject(:fields) { request_entry.controller_fields(controller) }

    context "with a signed-in user" do
      let(:user) { build_stubbed(:user) }
      let(:controller) { instance_double(ApplicationController, current_user: user) }

      it { is_expected.to eq("user.id" => user.id) }
    end

    context "without a signed-in user" do
      let(:controller) { instance_double(ApplicationController, current_user: nil) }

      it { is_expected.to eq("user.id" => nil) }
    end

    context "with a controller that has no current user" do
      let(:controller) { ActionController::Metal.new }

      it { is_expected.to eq("user.id" => nil) }
    end
  end
end
