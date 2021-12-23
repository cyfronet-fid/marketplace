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
      let!(:project_item) { create(:project_item, issue_id: issue_id) }

      before do
        data = create(:jira_webhook_response, issue_id: issue_id, issue_status: 6)
        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)
      end

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
      let!(:project_item) do
        create(
          :project_item,
          issue_id: issue_id,
          request_voucher: true,
          status: "registered",
          status_type: :registered,
          offer: create(:offer, voucherable: true)
        )
      end

      it "should grant voucher ID" do
        data =
          create(:jira_webhook_response, :voucher_id_change, issue_id: issue_id, issue_status: 6, voucher_id_to: "1234")

        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)

        project_item.reload
        expect(project_item.user_secrets).to include("voucher_id" => "1234")
        expect(project_item.messages.last&.message).to eq("Voucher has been granted to you, ID: 1234")
      end

      it "should update voucher ID" do
        project_item.update user_secrets: { voucher_id: "4321" }
        data =
          create(:jira_webhook_response, :voucher_id_change, issue_id: issue_id, issue_status: 6, voucher_id_to: "1234")

        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)

        project_item.reload
        expect(project_item.user_secrets).to include("voucher_id" => "1234")
        expect(project_item.messages.last&.message).to eq("Voucher ID has been updated: 1234")
      end

      it "should remove voucher ID" do
        project_item.update user_secrets: { voucher_id: "4321" }
        data =
          create(:jira_webhook_response, :voucher_id_change, issue_id: issue_id, issue_status: 6, voucher_id_to: "")

        post(api_webhooks_jira_url + "?secret=secret&issue_id=5", params: data)

        project_item.reload
        expect(project_item.user_secrets).to include("voucher_id" => "")
        expect(project_item.messages.last&.message).to eq("Voucher has been revoked")
      end
    end

    describe "update_comment" do
      issue_id = 123
      comment_id = 1234
      let!(:project_item) do
        create(
          :project_item,
          issue_id: issue_id,
          messages: [create(:message, iid: comment_id, message: "Initial message")]
        )
      end

      before do
        data = create(:jira_webhook_response, issue_id: issue_id, issue_status: 6)
        post(api_webhooks_jira_url + "?secret=secret&issue_id=#{issue_id}", params: data)
      end

      it "should update comment" do
        data =
          create(:jira_webhook_response, :comment_update, id: comment_id, issue_id: issue_id, message: "New message")
        post(api_webhooks_jira_url + "?secret=secret&issue_id=#{issue_id}", params: data)
        updated_message = Message.find_by(iid: comment_id)
        expect(updated_message.message).to eq("New message")
      end

      it "should create comment" do
        comment_id = 12_345
        data =
          create(:jira_webhook_response, :comment_update, id: comment_id, issue_id: issue_id, message: "New message")
        expect { post(api_webhooks_jira_url + "?secret=secret&issue_id=#{issue_id}", params: data) }.to change {
          project_item.messages.count
        }.by(1)
        updated_message = Message.find_by_iid(comment_id)
        expect(updated_message.public_scope?).to be_truthy
        expect(updated_message.role_provider?).to be_truthy
        expect(updated_message.message).to eq("New message")
      end
    end
  end
end
