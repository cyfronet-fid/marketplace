# frozen_string_literal: true

require "rails_helper"

class Sample < Jira::Checker
  block_error_handling :sample_method!
  block_error_handling :sample_error_method!

  def sample_error_method!
    raise StandardError
  end

  def sample_method!
  end
end

class MockWebhook
  include Rails.application.routes.url_helpers
  attr_reader :filters, :attrs, :enabled, :events

  def initialize(project_key, events = [])
    @filters = { "issue-related-events-section" => "project = #{project_key} " }
    @attrs = { "url" => ("http://localhost:2990" + api_webhooks_jira_path + "?issue_id=${issue.id}") }
    @events = events
    @enabled = true
  end
end

describe "block_error_handling", backend: true do
  let(:cls) { Sample.new(nil) }

  it "should wrap error in block" do
    cls.sample_error_method { |e| expect(e).to be_a StandardError }
  end

  it "errored method should return false" do
    expect(cls.sample_error_method).to be_falsey
  end

  it "should return true on no errors" do
    expect(cls.sample_method).to be_truthy
  end
end

describe Jira::Checker, backend: true do
  let(:checker) do
    jira_client =
      double(
        "Jira::Client",
        jira_project_key: "MP",
        jira_issue_type_id: 1,
        jira_config: {
          username: "user",
          url: "http://localhost/jira"
        },
        custom_fields: {
          "CI-Name": "customfield_10000",
          "CI-Surname": "customfield_10001"
        }
      )
    Jira::Checker.new(jira_client)
  end

  it "check_connection! should call client.Project.all" do
    expect(checker.client).to receive_message_chain("Project.all")
    checker.check_connection!
  end

  it "check_connection! should raise CriticalCheckerError on 401" do
    expect(checker.client).to receive_message_chain("Project.all").and_raise(
      JIRA::HTTPError.new(create(:response, code: "401"))
    )
    expect { checker.check_connection! }.to raise_error(
      Jira::Checker::CriticalCheckerError,
      "Could not authenticate #{checker.client.jira_config["username"]} on #{checker.client.jira_config["url"]}"
    )
  end

  it "check_issue_type! should call client.mp_issue_type" do
    expect(checker.client).to receive(:mp_issue_type)
    checker.check_issue_type!
  end

  it "check_issue_type! should raise CheckerError on 404" do
    expect(checker.client).to receive(:mp_issue_type).and_raise(JIRA::HTTPError.new(create(:response, code: "404")))
    expect { checker.check_issue_type! }.to raise_error(
      Jira::Checker::CheckerError,
      "It seems that ticket with id #{checker.client.jira_issue_type_id} does not exist, " \
        "make sure to add existing issue type into configuration"
    )
  end

  it "check_project! should call client.mp_project" do
    expect(checker.client).to receive(:mp_project)
    checker.check_project!
  end

  it "check_project! should raise CriticalCheckerError on 404" do
    expect(checker.client).to receive(:mp_project).and_raise(JIRA::HTTPError.new(create(:response, code: "404")))
    expect { checker.check_project! }.to raise_error(
      Jira::Checker::CriticalCheckerError,
      "Could not find project #{checker.client.jira_project_key}, " \
        "make sure it exists and user #{checker.client.jira_config["username"]} has access to it"
    )
  end

  describe "issue" do
    let(:issue) { double("Issue") }

    it "check_create_issue!" do
      expect(issue).to receive(:save).with(
        fields: {
          summary: "TEST TICKET, TO CHECK WHETHER JIRA INTEGRATION WORKS",
          project: {
            key: checker.client.jira_project_key
          },
          issuetype: {
            id: checker.client.jira_issue_type_id
          }
        }
      ).and_return(true)
      checker.check_create_issue! issue
    end

    it "check_update_issue!" do
      expect(issue).to receive(:save).with(fields: { description: "TEST DESCRIPTION" }).and_return(true)
      checker.check_update_issue! issue
    end

    it "check_add_comment!" do
      comment = double("Comment")
      expect(comment).to receive(:save).with(body: "TEST QUESTION").and_return(true)
      expect(issue).to receive_message_chain("comments.build").and_return(comment)
      checker.check_add_comment! issue
    end

    it "check_delete_issue!" do
      expect(issue).to receive(:delete).and_return(true)
      checker.check_delete_issue! issue
    end
  end

  describe "check_workflow!" do
    let(:id) { 5 }

    it "should call @client.Status.find" do
      expect(checker.client).to receive_message_chain("Status.find").with(id)
      checker.check_workflow! id
    end

    it "should throw error if status is not found" do
      expect(checker.client).to receive_message_chain("Status.find").and_raise(
        JIRA::HTTPError.new(create(:response, code: "404"))
      )
      expect { checker.check_workflow! id }.to raise_error(
        Jira::Checker::CheckerError,
        "STATUS WITH ID: #{id} DOES NOT EXIST IN JIRA"
      )
    end
  end

  describe "check_custom_fields!" do
    it "should not raise error if all custom fields are matched" do
      expect(checker.client).to receive_message_chain("Field.all").and_return(
        [
          double("Field", id: "customfield_10000", name: "CI-Name"),
          double("Field", id: "customfield_10001", name: "CI-Surname")
        ]
      )
      checker.check_custom_fields!
    end
    it "should raise error if any custom field is not mapped" do
      expect(checker.client).to receive_message_chain("Field.all").and_return(
        [double("Field", id: "customfield_10000", name: "CI-Name")]
      )
      expect { checker.check_custom_fields! }.to raise_error(
        Jira::Checker::CheckerCompositeError,
        "CUSTOM FIELD mapping have some problems"
      )
    end
  end

  describe "webhooks" do
    describe "check_webhook!" do
      it "should call client.Webhook.all and not raise if webhook was found" do
        webhook = MockWebhook.new(checker.client.jira_project_key)
        expect(checker.client).to receive_message_chain("Webhook.all").and_return([webhook])
        expect(checker).to receive(:check_webhook_params!)
        checker.check_webhook!("http://localhost:2990")
      end

      it "should raise CheckerWarning if jira instance has no webhooks" do
        expect(checker.client).to receive_message_chain("Webhook.all").and_return([])
        expect { checker.check_webhook!("http://localhost:2990") }.to raise_error(
          Jira::Checker::CheckerWarning,
          "JIRA instance has no defined webhooks"
        )
      end

      it "should raise CheckerWarning if no webhook was matched" do
        webhook = MockWebhook.new("AAA")
        expect(checker.client).to receive_message_chain("Webhook.all").and_return([webhook])
        expect { checker.check_webhook!("http://nonexistent") }.to raise_error(
          Jira::Checker::CheckerWarning,
          "Could not find Webhook for this application, " \
            "please confirm manually that webhook is defined for this host"
        )
      end
    end

    describe "check_webhook_params!" do
      it "should not rise if webhook has all required events" do
        events = %w[
          jira:issue_updated
          comment_created
          jira:issue_created
          comment_updated
          jira:issue_deleted
          comment_deleted
        ]

        checker.check_webhook_params!(MockWebhook.new(checker.client.jira_project_key, events))
      end

      it "should rise CheckerCompositeError detailing which event was not set" do
        events = %w[jira:issue_updated comment_created jira:issue_created]

        expected_statuses = {
          issue_updated: true,
          comment_created: true,
          issue_created: true,
          comment_updated: false,
          issue_deleted: false,
          comment_deleted: false
        }

        expect { checker.check_webhook_params!(MockWebhook.new(checker.client.jira_project_key, events)) }.to(
          raise_error do |error|
            expect(error).to be_a(Jira::Checker::CheckerCompositeError)
            expect(error.statuses).to eq(expected_statuses)
          end
        )
      end
    end
  end
end
