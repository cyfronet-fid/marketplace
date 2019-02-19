# frozen_string_literal: true

class Class
  def block_error_handling(*attrs)
    attrs.each do |method_name|
      define_method(method_name[0...-1]) do |*args, &error_handler|
        begin
          self.send(method_name, *args)
          return true
        rescue => e
          error_handler.call(e) if error_handler
        end
      end
    end
  end
end

class Jira::Checker
  include Rails.application.routes.url_helpers

  class CheckerError < StandardError; end
  class CheckerCompositeError < StandardError
    attr_accessor :statuses

    def initialize(message, statuses = {})
      super(message)
      @statuses = statuses
    end
  end
  class CheckerWarning < StandardError; end
  class CriticalCheckerError < StandardError; end

  def initialize(client = Jira::Client.new)
    @client = client
  end

  attr_reader :client

  block_error_handling :check_connection!
  block_error_handling :check_issue_type!
  block_error_handling :check_project!
  block_error_handling :check_create_issue!
  block_error_handling :check_update_issue!
  block_error_handling :check_add_comment!
  block_error_handling :check_delete_issue!
  block_error_handling :check_workflow!
  block_error_handling :check_workflow_transitions!
  block_error_handling :check_webhook!
  block_error_handling :check_custom_fields!

  def check_connection!
    begin
      self.client.Project.all
    rescue JIRA::HTTPError => e
      if e.response.code == "401"
        raise CriticalCheckerError.new("Could not authenticate #{self.client.jira_config["username"]} on #{self.client.jira_config["url"]}")
      else
        raise e
      end
    end
  end

  def check_issue_type!
    begin
      self.client.mp_issue_type
    rescue JIRA::HTTPError => e
      if e.response.code == "404"
        raise CheckerError.new("It seems that ticket with id #{client.jira_issue_type_id} does not exist, make sure to add existing issue type into configuration")
      end
      raise e
    end
  end

  def check_project!
    begin
      self.client.mp_project
    rescue JIRA::HTTPError => e
      if e.response.code == "404"
        raise CriticalCheckerError.new "Could not find project #{client.jira_project_key}, make sure it exists and user #{client.jira_config["username"]} has access to it"
      else
        raise e
      end
    end
  end

  def check_create_issue!(issue = nil)
    if issue == nil
      issue = self.client.Issue.build
    end

    unless issue.save(fields: { summary: "TEST TICKET, TO CHECK WHETHER JIRA INTEGRATION WORKS",
                                project: { key: self.client.jira_project_key },
                                issuetype: { id: self.client.jira_issue_type_id } })
      raise CriticalCheckerError.new "Could not create issue in project: #{self.client.jira_project_key} and issuetype: #{self.client.jira_issue_type_id}"
    end
  end

  def check_update_issue!(issue)
    unless issue.save(fields: { description: "TEST DESCRIPTION" })
      raise CheckerError.new "Could not update issue description"
    end
  end

  def check_add_comment!(issue)
    c = issue.comments.build
    unless c.save(body: "TEST QUESTION")
      raise CheckerError.new "Could not post comment"
    end
  end

  def check_delete_issue!(issue)
    begin
      issue.delete
    rescue JIRA::HTTPError => e
      if e.response.code == "403"
        raise CheckerWarning.new("Could not delete issue #{issue.key}, this is not critical but you will have to delete it manually from the project")
      else
        raise CheckerError.new("Could not delete issue, reason: #{e.response.code}: #{e.response.body}")
      end
    end
  end

  def check_workflow!(id)
    begin
      self.client.Status.find(id)
    rescue JIRA::HTTPError => e
      if e.response.code == "404"
        raise CheckerError.new("STATUS WITH ID: #{id} DOES NOT EXIST IN JIRA")
      else
        raise e
      end
    end
  end

  def check_workflow_transitions!(issue)
    begin
      trs = issue.transitions.all.select { |tr| tr.to.id.to_i == client.wf_done_id }
      if trs.length == 0
        raise CheckerError.new("Could not transition from 'TODO' to 'DONE' state, " +
                                   "this will affect open access services ")
      end
    end
  end

  def check_custom_fields!
    fields = client.Field.all

    statuses = self.client.custom_fields.map do |field_name, field_id|
      [field_name, fields.any? { |f| f.id == field_id && f.name.to_sym == field_name }]
    end .to_h

    if statuses.any? { |k, v| !v  }
      raise CheckerCompositeError.new("CUSTOM FIELD mapping have some problems",
                                      statuses)
    end
  end

  def check_webhook!(host)
    webhook = nil
    # noinspection RubyDeadCode
    client.Webhook.all.each do |wh|
      if wh.attrs["url"] == (host + api_webhooks_jira_path + "?issue_id=${issue.id}")
        unless wh.enabled
          raise CheckerWarning.new("Webhook \"#{wh.name}\" is not enabled")
        end

        if wh.filters["issue-related-events-section"].match(/project = #{self.client.jira_project_key}/)
          webhook = wh
        else
          raise CheckerWarning.new("Webhook \"#{wh.name}\" does not define proper \"Issue related events\" - required: " +
                                   "\"project = #{self.client.jira_project_key}\", current: \"#{wh.filters["issue-related-events-section"]}\"")
        end
      end
    end.empty? && begin
      raise CheckerWarning.new("JIRA instance has no defined webhooks")
    end

    raise CheckerWarning.new("Could not find Webhook for this application, please confirm manually that webhook is defined for this host") if webhook == nil

    self.check_webhook_params!(webhook)
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

    if statuses.select { |key, val| !val }.length > 0
      # noinspection RubyArgCount
      raise CheckerCompositeError.new("Webhook notifications are lacking", statuses)
    end
  end
end
