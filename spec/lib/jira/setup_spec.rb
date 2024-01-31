# frozen_string_literal: true

require "rails_helper"
require "jira/setup"

describe Jira::Setup, backend: true do
  let(:jira_project_key) { "MP" }
  let(:jira_client) { double("Jira::Client", jira_project_key: jira_project_key, jira_config: { username: "admin" }) }
  let(:setup) { Jira::Setup.new(jira_client) }
  let(:project) { double("Project") }

  it "call should check project existence" do
    expect(jira_client).to receive(:mp_project).and_return(true)
    expect { setup.call }.to output("Project #{jira_project_key} already exists\n").to_stdout
  end

  it "call should pass proper arguments to project.save" do
    # Disable stdout, to make it easier when running in terminal
    original_stdout = $stdout
    $stdout = StringIO.new

    expect(project).to receive(:save).with(
      key: jira_client.jira_project_key,
      name: jira_client.jira_project_key,
      projectTemplateKey: "com.atlassian.jira-core-project-templates:jira-core-project-management",
      projectTypeKey: "business",
      lead: jira_client.jira_config["username"]
    ).and_return(true)

    expect(jira_client).to receive(:mp_project).and_raise(JIRA::HTTPError.new(create(:response, code: "404")))
    expect(jira_client).to receive_message_chain("Project.build").and_return(project)
    setup.call

    $stdout = original_stdout
  end

  it "call should create project if no exists" do
    expect(project).to receive(:save).and_return(true)
    expect(jira_client).to receive(:mp_project).and_raise(JIRA::HTTPError.new(create(:response, code: "404")))
    expect(jira_client).to receive_message_chain("Project.build").and_return(project)
    expect { setup.call }.to output("Created project MP\n").to_stdout
  end

  it "call should abort with 'ERROR: Could not find project [500]' on http error 500" do
    errno = "500"

    # Disable stderr, to make it easier when running in terminal
    original_stderr = $stderr
    $stderr = StringIO.new

    expect(jira_client).to receive(:mp_project).and_raise(JIRA::HTTPError.new(create(:response, code: errno)))
    expect { setup.call }.to raise_error(SystemExit, "ERROR: Could not find project [#{errno}]")

    $stderr = original_stderr
  end

  it "call should abort with 'ERROR: Could not create project' if project could not be created" do
    # Disable stderr, to make it easier when running in terminal
    original_stderr = $stderr
    $stderr = StringIO.new

    expect(project).to receive(:save).and_return(false)
    expect(jira_client).to receive(:mp_project).and_raise(JIRA::HTTPError.new(create(:response, code: "404")))
    expect(jira_client).to receive_message_chain("Project.build").and_return(project)
    expect { setup.call }.to raise_error(SystemExit, "ERROR: Could not create project")

    $stderr = original_stderr
  end
end
