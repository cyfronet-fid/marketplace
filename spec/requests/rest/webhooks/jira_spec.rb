# frozen_string_literal: true

require "rails_helper"

RSpec.describe "JIRA Webhook API", type: :request do
  include Rails.application.routes.url_helpers
  include RequestSpecHelper

  before {
    jira_client     = double("Jira::Client",
                             jira_project_key: "MP",
                             jira_issue_type_id: 5,
                             webhook_secret: "secret",
                             wf_todo_id: 5,
                             wf_in_progress_id: 6,
                             wf_done_id: 7)
    jira_class_stub = class_double(Jira::Client).as_stubbed_const(transfer_nested_constants: true)
    allow(jira_class_stub).to receive(:new).and_return(jira_client)
  }

  describe "POST /api/webhooks/jira" do
    describe "wrong secret" do
      before {
        post api_webhooks_jira_path
      }

      it "returns error message" do
        expect(json).to eq("message" => "Secret does not match")
      end

      it "returns status code 400 if wrong secret is provided" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "Correct secret with data" do
      before {
        data = create(:jira_webhook_response)
        post(api_webhooks_jira_url + "?secret=secret", params: data)
      }

      it "returns status code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns 'no order changed' message" do
        expect(json).to eq("message" => "No correlating order found")
      end
    end

    describe "Correct secret with data" do
      issue_id = 5
      order = nil

      before {
        order = create(:order, issue_id: issue_id)
        data = create(:jira_webhook_response, issue_id: issue_id, issue_status: 6)
        post(api_webhooks_jira_url + "?secret=secret", params: data)
      }

      it "returns status code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns message: Updated" do
        expect(json).to eq("message" => "Updated")
      end

      it "should change order status" do
        expect(order.order_changes.last).to_not eq(nil)
      end
    end
  end
end
