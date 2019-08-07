# frozen_string_literal: true

require "rails_helper"

RSpec.describe "JIRA Webhook API", type: :request do
  include RequestSpecHelper
  include JiraHelper

  before { stub_jira }

  describe "POST /api/webhooks/jira" do
    describe "wrong secret" do
      before { post api_webhooks_jira_path }

      it "returns error message" do
        expect(json).to eq("message" => "Secret does not match")
      end

      it "returns status code 400 if wrong secret is provided" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "Correct secret with data" do
      issue_id = 5
      project_item = nil

      before {
        project_item = create(:project_item, issue_id: issue_id)
        data = create(:jira_webhook_response, issue_id: issue_id, issue_status: 6)
        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)
      }

      it "returns status code 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns message: Updated" do
        expect(json).to eq("message" => "Updated")
      end

      it "should change project_item status" do
        expect(project_item.statuses.last).to_not eq(nil)
      end
    end

    describe "Voucher ID" do
      issue_id = 5
      project_item = nil

      before {
        project_item = create(:project_item, issue_id: issue_id,
                              request_voucher: true,
                              status: :registered,
                              offer: create(:offer, voucherable: true))
      }

      it "should grant voucher ID" do
        data = create(:jira_webhook_response, :voucher_id_change, issue_id: issue_id, issue_status: 6, voucher_id_to: "1234")
        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)
        expect(project_item.messages.last&.message).to eq("Voucher has been granted to you, ID: 1234")
      end

      it "should update voucher ID" do
        project_item.update voucher_id: "4321"
        data = create(:jira_webhook_response, :voucher_id_change, issue_id: issue_id, issue_status: 6, voucher_id_to: "1234")
        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)
        expect(project_item.messages.last&.message).to eq("Voucher ID has been updated: 1234")
      end

      it "should remove voucher ID" do
        project_item.update voucher_id: "4321"
        data = create(:jira_webhook_response, :voucher_id_change, issue_id: issue_id, issue_status: 6, voucher_id_to: "")
        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)
        expect(project_item.messages.last&.message).to eq("Voucher has been revoked")
      end
    end
  end
end
