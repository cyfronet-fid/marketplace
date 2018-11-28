# frozen_string_literal: true

class Jira::Client < JIRA::Client
  include Rails.application.routes.url_helpers

  attr_reader :jira_config
  attr_reader :jira_project_key
  attr_reader :jira_issue_type_id
  attr_reader :webhook_secret
  attr_reader :custom_fields
  attr_reader :wf_todo_id, :wf_in_progress_id, :wf_done_id, :wf_rejected_id, :wf_waiting_for_response_id

  def initialize
    # read required options and initialize jira client
    @jira_config = Mp::Application.config_for(:jira)
    @webhook_secret = @jira_config["webhook_secret"]

    options = {
        username: @jira_config["username"],
        password: @jira_config["password"],
        site: @jira_config["url"],
        context_path: @jira_config["context_path"],
        auth_type: :basic,
        use_ssl: (/^https\:\/\// =~ @jira_config["url"])
    }

    @jira_project_key = @jira_config["project"]
    @jira_issue_type_id = @jira_config["issue_type_id"]

    @wf_todo_id = @jira_config["workflow"]["todo"]
    @wf_in_progress_id = @jira_config["workflow"]["in_progress"]
    @wf_done_id = @jira_config["workflow"]["done"]
    @wf_rejected_id = @jira_config["workflow"]["rejected"]
    @wf_waiting_for_response_id = @jira_config["workflow"]["waiting_for_response"]

    fields_config = @jira_config["custom_fields"]

    @custom_fields = {
      "Order reference": fields_config["Order reference"],
      "CI-Name": fields_config["CI-Name"],
      "CI-Surname": fields_config["CI-Surname"],
      "CI-Email": fields_config["CI-Email"],
      "CI-DisplayName": fields_config["CI-DisplayName"],
      "CI-EOSC-UniqueID": fields_config["CI-EOSC-UniqueID"],
      "CI-Institution": fields_config["CI-Institution"],
      "CI-Department": fields_config["CI-Department"],
      "CI-DepartmentalWebPage": fields_config["CI-DepartmentalWebPage"],
      "CI-SupervisorName": fields_config["CI-SupervisorName"],
      "CI-SupervisorProfile": fields_config["CI-SupervisorProfile"],
      "CP-CustomerTypology": fields_config["CP-CustomerTypology"],
      "CP-ReasonForAccess": fields_config["CP-ReasonForAccess"],
      # "CP-UserGroupName": "?", TODO -
      # "CP-ProjectInformation": "?", TODO -
      # For now only single Service Offer is supported
      "SO-1": fields_config["SO-1"]
    }

    super(options)
  end

  def create_service_issue(project_item)
    issue = self.Issue.build

    fields = { summary: "Service order, #{project_item.project.user.first_name} " +
                       "#{project_item.project.user.last_name}, " +
                       "#{project_item.service.title}",
              project: { key: @jira_project_key },
              issuetype: { id: @jira_issue_type_id },
    }

    @custom_fields.reject { |k, v| v.empty? }.each do |field_name, field_id|
      fields[field_id.to_s] = generate_custom_field_value(field_name.to_s, project_item)
    end

    issue.save(fields: fields) ? issue : nil
  end

  def mp_issue_type
    self.Issuetype.find(@jira_issue_type_id)
  end

  def mp_project
    self.Project.find(@jira_project_key)
  end

private

  def encode_properties(properties)
    properties.map { |p| "#{p["label"]}=#{p["value"]}" }.join("&")
  end

  def generate_custom_field_value(field_name, project_item)
    case field_name
    when "Order reference"
      ENV["ROOT_URL"].blank? ? project_item_path(project_item) : project_item_url(project_item, host: ENV["ROOT_URL"])
    when "CI-Name"
      project_item.project.user.first_name
    when "CI-Surname"
      project_item.project.user.last_name
    when "CI-Email"
      project_item.affiliation&.email || ""
    when "CI-DisplayName"
      "#{project_item.project.user.first_name} #{project_item.project.user.last_name}"
    when "CI-EOSC-UniqueID"
      project_item.project.user.uid
    when "CI-Institution"
      project_item.affiliation&.organization || ""
    when "CI-Department"
      project_item.affiliation&.department || ""
    when "CI-DepartmentalWebPage"
      project_item.affiliation&.webpage || ""
    when "CI-SupervisorName"
      project_item.affiliation&.supervisor || ""
    when "CI-SupervisorProfile"
      project_item.affiliation&.supervisor_profile || ""
    when "CP-CustomerTypology"
      project_item.customer_typology
    when "CP-ReasonForAccess"
      project_item.access_reason
    when "SO-1"
      "#{project_item.service.categories.first.name}/" +
      "#{project_item.service.title}/" +
      "#{encode_properties(project_item.properties)}"
    else
      ""
    end
  end
end
