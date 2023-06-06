# frozen_string_literal: true

require "rails_helper"

describe "jira:check", type: :task, backend: true do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "should call Jira::ConsoleChecker.check" do
    checker = double("Jira::ConsoleChecker")
    expect(checker).to receive(:check)
    expect(Jira::ConsoleChecker).to receive(:new).and_return(checker)
    subject.invoke
  end
end

describe "jira:setup", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "should call Jira::Setup.call" do
    setup = double("Jira::Setup")
    expect(setup).to receive(:call)
    expect(Jira::Setup).to receive(:new).and_return(setup)
    subject.invoke
  end
end

describe "jira:migrate_projects", type: :task do
  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "should call Jira::Setup.call" do
    instance = double("Jira::ProjectMigrator")
    expect(instance).to receive(:call)
    expect(Jira::ProjectMigrator).to receive(:new).and_return(instance)
    subject.invoke
  end
end
