# frozen_string_literal: true

require "colorize"

module Jira
  class ConsoleChecker
    def ok!
      print " OK".green << "\n"
      true
    end

    def abort!
      abort("jira:check exited with errors")
    end

    def error_and_abort!(error, indent = 1)
      print " FAIL".red << "\n"

      case error
      when Errno::ECONNREFUSED
        puts "ERROR".red + ": Could not connect to JIRA: #{@checker.client.jira_config["url"]}"
        abort!
      when Jira::Checker::CheckerError
        puts(("  " * indent) + "- ERROR".red + ": #{error.message}")
        false
      when Jira::Checker::CheckerWarning
        puts(("  " * indent) + "- WARNING".yellow + ": #{error.message}")
        false
      when Jira::Checker::CheckerCompositeError
        puts(("  " * indent) + "- ERROR".red + ": #{error.message}")

        error.statuses.each do |hash, value|
          print(("  " * (indent + 1)) + "- #{hash}:")
          value ? ok! : puts(" ✕".red)
        end
        false
      when Jira::Checker::CriticalCheckerError
        puts(("  " * indent) + "- ERROR".red + ": #{error.message}")
        abort!
      else
        puts "ERROR".red + ": Unexpected error occurred #{error.message}\n\n#{error.backtrace}"
        abort!
      end
    end

    def show_available_issue_types
      puts "AVAILABLE ISSUE TYPES: ".yellow
      if (@checker.client.Issuetype.all.each { |issue| puts "  - #{issue.name} [id: #{issue.id}]" }).empty?
        puts "  - NO ISSUE TYPES"
      end
    end

    def show_available_issue_states
      puts "AVAILABLE ISSUE STATES:".yellow
      @checker.client.Status.all.each { |state| puts "  - #{state.name} [id: #{state.id}]" }
    end

    def show_suggested_fields_mapping(mismatched_fields)
      fields = @checker.client.Field.all.select(&:custom)

      puts "SUGGESTED MAPPINGS"
      mismatched_fields.each do |field_name|
        suggested_field_description =
          if (f = fields.find { |fld| fld.name == field_name.to_s })
            "#{f.id.yellow} (export MP_JIRA_FIELD_#{f.name.gsub(/[- ]/, "_")}='#{f.id}')"
          else
            "NO MATCH FOUND".red
          end

        puts "  - #{field_name}: #{suggested_field_description}"
      end

      puts "AVAILABLE CUSTOM FIELDS"
      fields.each { |field| puts "  - #{field.name} [id: #{field.id}]" }
    end

    def initialize(checker = Jira::Checker.new, env = ENV)
      @checker = checker
      @env = env
    end

    def check
      puts "Checking JIRA instance on #{@checker.client.jira_config["url"]}"
      print "Checking connection..."
      @checker.check_connection { |e| error_and_abort!(e) } && ok!

      print "Checking issue type presence..."

      show_available_issue_types unless @checker.check_issue_type { |e| error_and_abort!(e) } && ok!

      print "Checking project existence..."
      @checker.check_project { |e| error_and_abort!(e) } && ok!

      puts "Trying to manipulate issue..."
      print "  - create issue..."
      issue = @checker.client.Issue.build
      @checker.check_create_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      print "  - check workflow transitions..."
      @checker.check_workflow_transitions(issue) { |e| error_and_abort!(e, 2) } && ok!

      print "  - update issue..."
      @checker.check_update_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      print "  - add comment to issue..."
      @checker.check_add_comment(issue) { |e| error_and_abort!(e, 2) } && ok!

      print "  - delete issue..."
      @checker.check_delete_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      puts "Checking workflow..."
      show_issue_states = false
      @checker.client.jira_config["workflow"].each do |key, id|
        print "  - #{key} [id: #{id}]..."
        show_issue_states = true unless @checker.check_workflow(id) { |e| error_and_abort!(e, 2) } && ok!
      end

      print "Checking custom fields mappings..."
      @checker.check_custom_fields do |e|
        error_and_abort!(e)

        show_suggested_fields_mapping(e.statuses.keys) if e.instance_of?(Jira::Checker::CheckerCompositeError)
      end && ok!

      # in case of mismatched issue states, print all available
      show_available_issue_states if show_issue_states

      print "Checking Project issue type presence..."

      show_available_issue_types unless @checker.check_project_issue_type { |e| error_and_abort!(e) } && ok!

      puts "Trying to manipulate project issue..."
      print "  - create issue..."
      issue = @checker.client.Issue.build
      @checker.check_create_project_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      print "  - update issue..."
      @checker.check_update_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      print "  - delete issue..."
      @checker.check_delete_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      check_webhook
    end

    def check_webhook
      if @env["MP_HOST"].nil?
        puts "WARNING: Webhook won't be check, set MP_HOST env variable if you want to check it".yellow
      else
        print "Checking webhooks for hostname \"#{@env["MP_HOST"]}\"..."
        @checker.check_webhook(@env["MP_HOST"]) { |e| error_and_abort!(e) } && ok!
      end
    end
  end
end
