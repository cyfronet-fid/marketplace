# frozen_string_literal: true

require "colorize"

module Jira
  class ProjectMigrator
    def initialize(client = Jira::Client.new)
      @client = client
    end

    def call
      Project.where(issue_status: :jira_require_migration).each do |project|
        issue = @client.create_project_issue project
        project.update_columns(issue_id: issue.id, issue_key: issue.key,
                               issue_status: :jira_active)

        Rails.logger.debug { "Created issue for Project with ID '#{project.id}' - JIRA issue: #{issue.key}" }

        project.project_items.each do |pi|
          if pi.issue_id.nil?
            Rails.logger.debug "WARNING".yellow + " Project Item with id #{pi.id} does not have issue_id! Please review it manually"
            next
          end

          issue = @client.Issue.find(pi.issue_id)

          unless issue.save(fields: { @client.custom_fields[:"Epic Link"].to_s => project.issue_key })
            Rails.logger.debug "ERROR".red + " Could not link epic #{project.issue_key} to #{issue.key}"
          end
        rescue JIRA::HTTPError => e
          if e.code == "404"
            Rails.logger.debug "WARNING".yellow + " Issue with jira id: #{pi.issue_id} does not exist in JIRA, skipping..."
            pi.jira_deleted!
          else
            Rails.logger.debug "ERROR".red + " Issue for Project Item with id #{pi.id} could not be updated! Please review it manually"
            pi.jira_errored!
          end
        end

      rescue Jira::Client::JIRAIssueCreateError => e
        project.jira_errored!
        raise e
      end.empty? && begin
        Rails.logger.debug "There are not projects requiring migration"
      end
    end
  end
end
