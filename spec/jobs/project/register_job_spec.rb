# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project::ProjectRegisterJob, backend: true do
  let(:project_owner) { create(:user) }
  let(:project) do
    project = create(:project, user: project_owner)
    expect(Project::Register).to receive(:new).with(project).and_return(register_service)
    next project
  end
  let(:register_service) { instance_double(Project::Register) }

  it "triggers registration process for project" do
    expect(register_service).to receive(:call)
    described_class.perform_now(project)
  end

  it "should recast exceptions cast by Project::Register" do
    error = Jira::Client::JIRAIssueCreateError.new(project)

    expect(register_service).to receive(:call).and_raise(error)

    expect { described_class.perform_now(project) }.to raise_error(error)
  end
end
