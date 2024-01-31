# frozen_string_literal: true

class Class
  def block_error_handling(*attrs)
    attrs.each do |method_name|
      define_method(method_name[0...-1]) do |*args, &error_handler|
        send(method_name, *args)
        true
      rescue StandardError => e
        error_handler&.call(e)
      end
    end
  end
end

class Jira::Checker
  include Rails.application.routes.url_helpers

  class CheckerError < StandardError
  end
  class CheckerCompositeError < StandardError
    attr_accessor :statuses

    def initialize(message, statuses = {})
      super(message)
      @statuses = statuses
    end
  end
  class CheckerWarning < StandardError
  end
  class CriticalCheckerError < StandardError
  end

  def initialize(client = Jira::Client.new)
    @client = client
  end

  attr_reader :client

  block_error_handling :check_connection!
  block_error_handling :check_issue_type!
  block_error_handling :check_project_issue_type!
  block_error_handling :check_project!
  block_error_handling :check_create_issue!
  block_error_handling :check_create_project_issue!
  block_error_handling :check_update_issue!
  block_error_handling :check_add_comment!
  block_error_handling :check_delete_issue!
  block_error_handling :check_workflow!
  block_error_handling :check_workflow_transitions!
  block_error_handling :check_webhook!
  block_error_handling :check_custom_fields!

  def check_connection!
    client.Project.all
  rescue JIRA::HTTPError => e
    if e.response.code == "401"
      raise CriticalCheckerError,
            "Could not authenticate #{client.jira_config["username"]} on #{client.jira_config["url"]}"
    else
      raise e
    end
  end

  def check_issue_type!
    client.mp_issue_type
  rescue JIRA::HTTPError => e
    if e.response.code == "404"
      raise CheckerError,
            "It seems that ticket with id #{client.jira_issue_type_id} does not exist, make sure to add existing issue type into configuration"
    end
    raise e
  end

  def check_project_issue_type!
    client.mp_project_issue_type
  rescue JIRA::HTTPError => e
    if e.response.code == "404"
      raise CheckerError,
            "It seems that ticket with id #{client.jira_project_issue_type_id} does not exist, make sure to add existing issue type into configuration"
    end
    raise e
  end

  def check_project!
    client.mp_project
  rescue JIRA::HTTPError => e
    if e.response.code == "404"
      raise CriticalCheckerError,
            "Could not find project #{client.jira_project_key}, make sure it exists and user #{client.jira_config["username"]} has access to it"
    else
      raise e
    end
  end

  def check_create_issue!(issue = nil)
    issue = client.Issue.build if issue.nil?

    unless issue.save(
             fields: {
               summary: "TEST TICKET, TO CHECK WHETHER JIRA INTEGRATION WORKS",
               project: {
                 key: client.jira_project_key
               },
               issuetype: {
                 id: client.jira_issue_type_id
               }
             }
           )
      raise CriticalCheckerError,
            "Could not create issue in project: #{client.jira_project_key} and issuetype: #{client.jira_issue_type_id}"
    end
  end

  def check_create_project_issue!(issue = nil)
    issue = client.Issue.build if issue.nil?

    fields = {
      summary: "TEST PROJECT, TO CHECK WHETHER JIRA INTEGRATION WORKS",
      project: {
        key: client.jira_project_key
      },
      issuetype: {
        id: client.jira_project_issue_type_id
      }
    }
    fields[client.custom_fields[:"Epic Name"]] = "TEST EPIC"

    unless issue.save(fields: fields)
      raise CriticalCheckerError,
            "Could not create product issue in project: #{client.jira_project_key} and issuetype: #{client.jira_project_issue_type_id}"
    end
  end

  def check_update_issue!(issue)
    unless issue.save(fields: { description: "TEST DESCRIPTION" })
      raise CheckerError, "Could not update issue description"
    end
  end

  def check_add_comment!(issue)
    c = issue.comments.build
    raise CheckerError, "Could not post comment" unless c.save(body: "TEST QUESTION")
  end

  def check_delete_issue!(issue)
    issue.delete
  rescue JIRA::HTTPError => e
    if e.response.code == "403"
      raise CheckerWarning,
            "Could not delete issue #{issue.key}, this is not critical but you will have to delete it manually from the project"
    else
      raise CheckerError, "Could not delete issue, reason: #{e.response.code}: #{e.response.body}"
    end
  end

  def check_workflow!(id)
    client.Status.find(id)
  rescue JIRA::HTTPError => e
    if e.response.code == "404"
      raise CheckerError, "STATUS WITH ID: #{id} DOES NOT EXIST IN JIRA"
    else
      raise e
    end
  end

  def check_workflow_transitions!(issue)
    trs = issue.transitions.all.select { |tr| tr.to.id.to_i == client.wf_done_id }
    if trs.empty?
      raise CheckerError,
            "Could not transition from 'TODO' to 'DONE' state, " + "this will affect open access services "
    end
  end

  def check_custom_fields!
    fields = client.Field.all

    statuses =
      client.custom_fields.to_h do |field_name, field_id|
        [field_name, fields.any? { |f| f.id == field_id && f.name.to_sym == field_name }]
      end

    raise CheckerCompositeError.new("CUSTOM FIELD mapping have some problems", statuses) if statuses.any? { |_k, v| !v }
  end

  def check_webhook!(host)
    webhook = nil

    # noinspection RubyDeadCode
    client
      .Webhook
      .all
      .each do |wh|
        next unless wh.attrs["url"] == (host + api_webhooks_jira_path + "?issue_id=${issue.id}")
        raise CheckerWarning, "Webhook \"#{wh.name}\" is not enabled" unless wh.enabled

        if wh.filters["issue-related-events-section"].match?(/project = #{client.jira_project_key}/)
          webhook = wh
        else
          raise CheckerWarning,
                "Webhook \"#{wh.name}\" does not define proper \"Issue related events\" - required: " \
                  "\"project = #{client.jira_project_key}\", current: \"#{wh.filters["issue-related-events-section"]}\""
        end
      end
      .empty? &&
      begin
        raise CheckerWarning, "JIRA instance has no defined webhooks"
      end

    if webhook.nil?
      raise CheckerWarning,
            "Could not find Webhook for this application, please confirm manually that webhook is defined for this host"
    end

    check_webhook_params!(webhook)
  end

  def check_webhook_params!(webhook)
    statuses = {
      issue_updated: webhook.events.include?("jira:issue_updated"),
      comment_created: webhook.events.include?("comment_created"),
      issue_created: webhook.events.include?("jira:issue_created"),
      comment_updated: webhook.events.include?("comment_updated"),
      issue_deleted: webhook.events.include?("jira:issue_deleted"),
      comment_deleted: webhook.events.include?("comment_deleted")
    }

    unless statuses.reject { |_key, val| val }.empty?
      # noinspection RubyArgCount
      raise CheckerCompositeError.new("Webhook notifications are lacking", statuses)
    end
  end
end
