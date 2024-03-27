# frozen_string_literal: true

require "rails_helper"
require "jira/console_checker"
require "colorize"

describe Jira::ConsoleChecker, backend: true do
  let(:checker) do
    double(
      "Jira::Checker",
      client:
        double(
          "Jira::Client",
          jira_config: {
            "url" => "http://localhost:2990",
            "workflow" => {
              "todo" => 1,
              "in_progress" => 2,
              "waiting_for_response" => 4,
              "done" => 3,
              "rejected" => 5
            }
          }
        )
    )
  end
  let(:con_checker) { Jira::ConsoleChecker.new(checker, {}) }

  it "abort! should exit with 'jira:check exited with errors' message" do
    # Disable stdout, to make it easier when running in terminal
    original_stdout = $stderr
    $stderr = StringIO.new

    expect { con_checker.abort! }.to raise_error(SystemExit, "jira:check exited with errors")
    $stderr = original_stdout
  end

  it "ok! should print green OK" do
    expect { con_checker.ok! }.to output(" OK".green << "\n").to_stdout
  end

  describe "error_and_abort!" do
    it "should print FAIL and error type to stdout" do
      expect(con_checker).to receive(:abort!)
      expect { con_checker.error_and_abort!(StandardError.new) }.to output(
        " FAIL".red + "\n" + "ERROR".red + ": Unexpected error occurred StandardError\n\n"
      ).to_stdout
    end

    it "should handle Errno::ECONNREFUSED" do
      expect(con_checker).to receive(:abort!)
      expect { con_checker.error_and_abort!(Errno::ECONNREFUSED.new) }.to output(
        " FAIL".red + "\n" + "ERROR".red + ": Could not connect to JIRA: #{checker.client.jira_config["url"]}\n"
      ).to_stdout
    end

    it "should handle Jira::Checker::CheckerError and return false" do
      message = "MSG"
      output = true
      expect { output = con_checker.error_and_abort!(Jira::Checker::CheckerError.new(message)) }.to output(
        " FAIL".red + "\n" + "  " + "- ERROR".red + ": #{message}\n"
      ).to_stdout
      expect(output).to be_falsey
    end

    it "should handle Jira::Checker::CheckerWarning and return false" do
      message = "MSG"
      output = true
      expect { output = con_checker.error_and_abort!(Jira::Checker::CheckerWarning.new(message)) }.to output(
        " FAIL".red + "\n" + "  " + "- WARNING".yellow + ": #{message}\n"
      ).to_stdout
      expect(output).to be_falsey
    end

    it "should handle Jira::Checker::CriticalCheckerError and abort" do
      message = "MSG"
      expect(con_checker).to receive(:abort!)
      expect { con_checker.error_and_abort!(Jira::Checker::CriticalCheckerError.new(message)) }.to output(
        " FAIL".red + "\n" + "  " + "- ERROR".red + ": #{message}\n"
      ).to_stdout
    end

    it "should handle Jira::Checker::CheckerCompositeError and return false" do
      message = "MSG"
      output = true

      # noinspection RubyArgCount
      expect do
        output = con_checker.error_and_abort!(Jira::Checker::CheckerCompositeError.new(message, status: false))
      end.to output(
        " FAIL".red + "\n" + "  " + "- ERROR".red + ": #{message}\n    - status:" + " ✕".red + "\n"
      ).to_stdout
      expect(output).to be_falsey
    end
  end

  it "show_available_issue_types should print 'NO ISSUE TYPES' if no issue types are defined" do
    expect(checker.client).to receive_message_chain("Issuetype.all").and_return([])
    expect { con_checker.show_available_issue_types }.to output(
      "AVAILABLE ISSUE TYPES: ".yellow + "\n" + "  - NO ISSUE TYPES\n"
    ).to_stdout
  end

  it "show_available_issue_types should print list of issue types" do
    expect(checker.client).to receive_message_chain("Issuetype.all").and_return([double("Issue", name: "ISSUE", id: 1)])
    expect { con_checker.show_available_issue_types }.to output(
      "AVAILABLE ISSUE TYPES: ".yellow + "\n" + "  - ISSUE [id: 1]\n"
    ).to_stdout
  end

  it "show_available_issue_states should print list of issue states" do
    expect(checker.client).to receive_message_chain("Status.all").and_return([double("Status", name: "NAME", id: 1)])
    expect { con_checker.show_available_issue_states }.to output(
      "AVAILABLE ISSUE STATES:".yellow + "\n" + "  - NAME [id: 1]\n"
    ).to_stdout
  end

  it "check_webhook should print warning if MP_HOST env is not set" do
    expect { con_checker.check_webhook }.to output(
      "WARNING: Webhook won't be check, set MP_HOST env variable if you want to check it".yellow + "\n"
    ).to_stdout
  end

  it "check_webhook should call checker with MP_HOST env if it's set" do
    host = "http://localhost:5000"

    # noinspection RubyStringKeysInHashInspection
    con_checker = Jira::ConsoleChecker.new(checker, "MP_HOST" => host)
    expect(checker).to receive(:check_webhook).with(host).and_return(true)
    expect { con_checker.check_webhook }.to output(
      "Checking webhooks for hostname \"#{host}\"..." + " OK".green + "\n"
    ).to_stdout
  end

  it "check should print to stdout" do
    allow(checker.client).to receive_message_chain("Issue.build").and_return(double("Issue"))

    expect(checker).to receive(:check_connection).and_return(true)
    expect(checker).to receive(:check_project).and_return(true)
    expect(checker).to receive(:check_create_issue).and_return(true)
    expect(checker).to receive(:check_update_issue).twice.and_return(true)
    expect(checker).to receive(:check_add_comment).and_return(true)
    expect(checker).to receive(:check_delete_issue).twice.and_return(true)
    expect(checker).to receive(:check_workflow).exactly(5).and_return(true)
    expect(checker).to receive(:check_issue_type).and_return(true)
    expect(checker).to receive(:check_workflow_transitions).and_return(true)
    expect(checker).to receive(:check_custom_fields).and_return(true)
    expect(checker).to receive(:check_project_issue_type).and_return(true)
    expect(checker).to receive(:check_create_project_issue).and_return(true)

    expect { con_checker.check }.to output(
      "Checking JIRA instance on http://localhost:2990\n" + "Checking connection..." + " OK".green +
        "\n" \
          "Checking issue type presence..." + " OK".green + "\n" + "Checking project existence..." + " OK".green +
        "\n" \
          "Trying to manipulate issue...\n" + "  - create issue..." + " OK".green +
        "\n" \
          "  - check workflow transitions..." + " OK".green + "\n" + "  - update issue..." + " OK".green +
        "\n" \
          "  - add comment to issue..." + " OK".green + "\n" + "  - delete issue..." + " OK".green +
        "\n" \
          "Checking workflow...\n" + "  - todo [id: 1]..." + " OK".green + "\n" + "  - in_progress [id: 2]..." +
        " OK".green + "\n" + "  - waiting_for_response [id: 4]..." + " OK".green + "\n" + "  - done [id: 3]..." +
        " OK".green + "\n" + "  - rejected [id: 5]..." + " OK".green + "\n" + "Checking custom fields mappings..." +
        " OK".green + "\n" + "Checking Project issue type presence..." + " OK".green +
        "\n" \
          "Trying to manipulate project issue...\n" + "  - create issue..." + " OK".green +
        "\n" \
          "  - update issue..." + " OK".green + "\n" + "  - delete issue..." + " OK".green + "\n" +
        "WARNING: Webhook won't be check, set MP_HOST env variable if you want to check it".yellow + "\n"
    ).to_stdout
  end

  it "all checks should execute it's error blocks when errored" do
    error = Errno::ECONNREFUSED.new

    # Disable stdout, to make it easier when running in terminal
    original_stdout = $stdout
    $stdout = StringIO.new

    expect(con_checker).to receive(:show_available_issue_types).twice
    expect(con_checker).to receive(:show_available_issue_states)

    allow(checker.client).to receive_message_chain("Issue.build").and_return(double("Issue"))

    expect(checker).to receive(:check_connection) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to receive(:check_project) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to receive(:check_issue_type) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to receive(:check_create_issue) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to receive(:check_workflow_transitions) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to(
      receive(:check_update_issue).twice do |&block|
        block.call(error)
        next false
      end
    )
    expect(checker).to receive(:check_add_comment) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to(
      receive(:check_delete_issue).twice do |&block|
        block.call(error)
        next false
      end
    )
    expect(checker).to receive(:check_workflow).exactly(5) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to receive(:check_custom_fields) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to receive(:check_project_issue_type) { |&block|
      block.call(error)
      next false
    }
    expect(checker).to receive(:check_create_project_issue) { |&block|
      block.call(error)
      next false
    }

    expect(con_checker).to receive(:error_and_abort!).exactly(18).with(error, any_args)
    con_checker.check

    $stdout = original_stdout
  end
end
