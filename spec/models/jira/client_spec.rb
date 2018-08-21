# frozen_string_literal: true

require "rails_helper"

describe Jira::Client do
  let(:client) { Jira::Client.new }

  it "should Issuetype when calling mp_issue_type" do
    return_val = :issue_type
    expect(client).to receive_message_chain("Issuetype.find").with(client.jira_issue_type_id).and_return(return_val)
    expect(client.mp_issue_type).to equal(return_val)
  end

  it "should find Project when calling mp_project" do
    return_val = :project
    expect(client).to receive_message_chain("Project.find").with(client.jira_project_key).and_return(return_val)
    expect(client.mp_project).to equal(return_val)
  end
end
