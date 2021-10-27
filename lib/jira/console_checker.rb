# frozen_string_literal: true

require "colorize"

module Jira
  class ConsoleChecker
    def ok!
      Rails.logger.debug " OK".green << "\n"
      true
    end

    def abort!
      abort("jira:check exited with errors")
    end

    def error_and_abort!(e, indent = 1)
      Rails.logger.debug " FAIL".red << "\n"

      case e
      when Errno::ECONNREFUSED
        Rails.logger.debug "ERROR".red + ": Could not connect to JIRA: #{@checker.client.jira_config['url']}"
        abort!

      when Jira::Checker::CheckerError
        Rails.logger.debug(("  " * indent) + "- ERROR".red + ": #{e.message}")
        false

      when Jira::Checker::CheckerWarning
        Rails.logger.debug(("  " * indent) + "- WARNING".yellow + ": #{e.message}")
        false

      when Jira::Checker::CheckerCompositeError
        Rails.logger.debug(("  " * indent) + "- ERROR".red + ": #{e.message}")

        e.statuses.each do |hash, value|
          Rails.logger.debug(("  " * (indent + 1)) + "- #{hash}:")
          value ? ok! : Rails.logger.debug(" ✕".red)
        end
        false
      when Jira::Checker::CriticalCheckerError
        Rails.logger.debug(("  " * indent) + "- ERROR".red + ": #{e.message}")
        abort!

      else
        Rails.logger.debug "ERROR".red + ": Unexpected error ocurred #{e.message}\n\n#{e.backtrace}"
        abort!
      end
    end

    def show_available_issue_types
      Rails.logger.debug "AVAILABLE ISSUE TYPES: ".yellow
      if (@checker.client.Issuetype.all.each do |issue|
        Rails.logger.debug "  - #{issue.name} [id: #{issue.id}]"
      end).empty?
        Rails.logger.debug "  - NO ISSUE TYPES"
      end
    end

    def show_available_issue_states
      Rails.logger.debug "AVAILABLE ISSUE STATES:".yellow
      @checker.client.Status.all.each do |state|
        Rails.logger.debug "  - #{state.name} [id: #{state.id}]"
      end
    end

    def show_suggested_fields_mapping(mismatched_fields)
      fields = @checker.client.Field.all.select(&:custom)

      Rails.logger.debug "SUGGESTED MAPPINGS"
      mismatched_fields.each do |field_name|
        suggested_field_description = if (f = fields.find { |_f| _f.name == field_name.to_s })
                                        "#{f.id.yellow} (export MP_JIRA_FIELD_#{f.name.gsub(/[- ]/, '_')}='#{f.id}')"
                                      else
                                        "NO MATCH FOUND".red
                                      end

        Rails.logger.debug { "  - #{field_name}: #{suggested_field_description}" }
      end

      Rails.logger.debug "AVAILABLE CUSTOM FIELDS"
      fields.each do |field|
        Rails.logger.debug "  - #{field.name} [id: #{field.id}]"
      end
    end

    def initialize(checker = Jira::Checker.new, env = ENV)
      @checker = checker
      @env = env
    end

    def check
      Rails.logger.debug { "Checking JIRA instance on #{@checker.client.jira_config['url']}" }
      Rails.logger.debug "Checking connection..."
      @checker.check_connection { |e| error_and_abort!(e) } && ok!

      Rails.logger.debug "Checking issue type presence..."

      show_available_issue_types unless @checker.check_issue_type { |e| error_and_abort!(e) } && ok!

      Rails.logger.debug "Checking project existence..."
      @checker.check_project { |e| error_and_abort!(e) } && ok!

      Rails.logger.debug "Trying to manipulate issue..."
      Rails.logger.debug "  - create issue..."
      issue = @checker.client.Issue.build
      @checker.check_create_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      Rails.logger.debug "  - check workflow transitions..."
      @checker.check_workflow_transitions(issue) { |e| error_and_abort!(e, 2) } && ok!

      Rails.logger.debug "  - update issue..."
      @checker.check_update_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      Rails.logger.debug "  - add comment to issue..."
      @checker.check_add_comment(issue) { |e| error_and_abort!(e, 2) } && ok!

      Rails.logger.debug "  - delete issue..."
      @checker.check_delete_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      Rails.logger.debug "Checking workflow..."
      show_issue_states = false
      @checker.client.jira_config["workflow"].each do |key, id|
        Rails.logger.debug { "  - #{key} [id: #{id}]..." }
        show_issue_states = true unless @checker.check_workflow(id) { |e| error_and_abort!(e, 2) } && ok!
      end

      Rails.logger.debug "Checking custom fields mappings..."
      @checker.check_custom_fields do |e|
        error_and_abort!(e)

        show_suggested_fields_mapping(e.statuses.keys) if e.instance_of?(Jira::Checker::CheckerCompositeError)
      end && ok!

      # in case of mismatched issue states, print all available
      show_available_issue_states if show_issue_states

      Rails.logger.debug "Checking Project issue type presence..."

      show_available_issue_types unless @checker.check_project_issue_type do |e|
                                          error_and_abort!(e)
                                        end && ok!

      Rails.logger.debug "Trying to manipulate project issue..."
      Rails.logger.debug "  - create issue..."
      issue = @checker.client.Issue.build
      @checker.check_create_project_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      Rails.logger.debug "  - update issue..."
      @checker.check_update_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      Rails.logger.debug "  - delete issue..."
      @checker.check_delete_issue(issue) { |e| error_and_abort!(e, 2) } && ok!

      check_webhook
    end

    def check_webhook
      if @env["MP_HOST"].nil?
        Rails.logger.debug "WARNING: Webhook won't be check, set MP_HOST env variable if you want to check it".yellow
      else
        Rails.logger.debug { "Checking webhooks for hostname \"#{@env['MP_HOST']}\"..." }
        @checker.check_webhook(@env["MP_HOST"]) { |e| error_and_abort!(e) } && ok!
      end
    end
  end
end
