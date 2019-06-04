# frozen_string_literal: true

class Jira::Client < JIRA::Client
  include Rails.application.routes.url_helpers

  class JIRAIssueCreateError < StandardError
  end

  class JIRAProjectItemIssueCreateError < JIRAIssueCreateError
    def initialize(project_item, msg = "")
      super(msg)
      @project_item = project_item
    end
  end

  class JIRAProjectIssueCreateError < JIRAIssueCreateError
    def initialize(project, msg = "")
      super(msg)
      @project = project
    end
  end

  class ProjectIssueDoesNotExist < StandardError
    def initialize(project, msg = "")
      super(msg)
      @project = project
    end
  end

  attr_reader :jira_config
  attr_reader :jira_project_key
  attr_reader :jira_issue_type_id, :jira_project_issue_type_id
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
    @jira_project_issue_type_id = @jira_config["project_issue_type_id"]

    @wf_todo_id = @jira_config["workflow"]["todo"]
    @wf_in_progress_id = @jira_config["workflow"]["in_progress"]
    @wf_done_id = @jira_config["workflow"]["done"]
    @wf_rejected_id = @jira_config["workflow"]["rejected"]
    @wf_waiting_for_response_id = @jira_config["workflow"]["waiting_for_response"]

    fields_config = @jira_config["custom_fields"]

    @custom_fields = {
      "Epic Link": fields_config["Epic Link"],
      "Epic Name": fields_config["Epic Name"],
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
      "CP-CustomerCountry": fields_config["CP-CustomerCountry"],
      "CP-CustomerTypology": fields_config["CP-CustomerTypology"],
      "CP-CollaborationCountry": fields_config["CP-CollaborationCountry"],
      "CP-ReasonForAccess": fields_config["CP-ReasonForAccess"],
      "CP-UserGroupName": fields_config["CP-UserGroupName"],
      "CP-ProjectInformation": fields_config["CP-ProjectInformation"],
      "CP-ScientificDiscipline": fields_config["CP-ScientificDiscipline"],
      "CP-Platforms": fields_config["CP-Platforms"],
      "CP-INeedAVoucher": fields_config["CP-INeedAVoucher"],
      "CP-VoucherID": fields_config["CP-VoucherID"],
      # For now only single Service Offer is supported
      "SO-ProjectName": fields_config["SO-ProjectName"],
      "SO-1": fields_config["SO-1"],
      "SO-ServiceOrderTarget": fields_config["SO-ServiceOrderTarget"],
      "SO-OfferType": fields_config["SO-OfferType"]
    }

    super(options)
  end

  def create_project_issue(project)
    issue = self.Issue.build

    fields = { summary: "Project, #{project.user.first_name} " +
                        "#{project.user.last_name}, " +
                        "#{project.name}",
               project: { key: @jira_project_key },
               issuetype: { id: @jira_project_issue_type_id },
    }

    @custom_fields.reject { |k, v| v.empty? }.each do |field_name, field_id|
      value = generate_project_custom_field_value(field_name.to_s, project)
      unless value.nil?
        fields[field_id.to_s] = value
      end
    end

    if issue.save(fields: fields)
      issue
    else
      raise JIRAProjectIssueCreateError.new(project, issue.errors)
    end
  end


  def create_service_issue(project_item)
    unless project_item.project.jira_active?
      raise ProjectIssueDoesNotExist.new(project_item.project)
    end

    issue = self.Issue.build

    fields = { summary: "Service order, #{project_item.project.user.first_name} " +
                       "#{project_item.project.user.last_name}, " +
                       "#{project_item.service.title}",
              project: { key: @jira_project_key },
              issuetype: { id: @jira_issue_type_id },
    }

    @custom_fields.reject { |k, v| v.empty? }.each do |field_name, field_id|
      value = generate_project_item_custom_field_value(field_name.to_s, project_item)
      unless value.nil?
        fields[field_id.to_s] = value
      end
    end

    if issue.save(fields: fields)
      issue
    else
      raise JIRAProjectItemIssueCreateError.new(project_item, issue.errors)
    end
  end

  def mp_issue_type
    self.Issuetype.find(@jira_issue_type_id)
  end

  def mp_project_issue_type
    self.Issuetype.find(@jira_project_issue_type_id)
  end

  def mp_project
    self.Project.find(@jira_project_key)
  end

private

  def encode_properties(properties)
    properties.map { |p| [ p["label"],  p["value"] ] }.to_h
  end

  def encode_order_properties(project_item)
    {
      "category" => project_item.service.categories.first.name,
      "service" => project_item.service.title,
      "offer" => project_item.offer&.name,
      "attributes" => encode_properties(project_item.properties)
    }.to_json
  end

  def generate_project_custom_field_value(field_name, project)
    case field_name
    when "Epic Name"
      project.name
    when "CI-Name"
      project.user.first_name
    when "CI-Surname"
      project.user.last_name
    when "CI-Email"
      project.user.email || nil
    when "CI-DisplayName"
      "#{project.user.first_name} #{project.user.last_name}"
    when "CI-EOSC-UniqueID"
      project.user.uid
    when "CP-CustomerTypology"
      if project.customer_typology
        { "id" => @jira_config["custom_fields"]["select_values"]["CP-CustomerTypology"][project.customer_typology] }
      else
        nil
      end
    when "CP-CustomerCountry"
      project.country_of_customer
    when "CP-CollaborationCountry"
      project.country_of_collaboration.join(", ")
    # when "CP-ReasonForAccess"
    #   project.reason_for_access
    # when "CP-ProjectInformation"
    #   project.name
    when "CP-UserGroupName"
      project.user_group_name
    when "SO-ProjectName"
      "#{project&.name} (#{project&.id})"
    # this is not a property of project
    # when "CP-ScientificDiscipline"
    #   project.research_area&.name
    else
      nil
    end
  end

  def generate_project_item_custom_field_value(field_name, project_item)
    case field_name
    when "Order reference"
      ENV["ROOT_URL"].blank? ? project_item_path(project_item) : project_item_url(project_item, host: ENV["ROOT_URL"])
    when "Epic Link"
      project_item.project.issue_key
    when "CP-Platforms"
      project_item.offer.service.platforms.pluck(:name).join(", ")
    when "CP-INeedAVoucher"
      { "id" => @jira_config["custom_fields"]["select_values"]["CP-INeedAVoucher"][project_item.request_voucher] }
    when "CP-VoucherID"
      project_item.voucher_id || nil
    when "CP-ScientificDiscipline"
      project_item.research_area&.name
    when "SO-1"
      encode_order_properties(project_item)
    when "SO-ServiceOrderTarget"
      project_item.service.order_target
    when "SO-OfferType"
      { "id" => @jira_config["custom_fields"]["select_values"]["SO-OfferType"][project_item.offer.offer_type] }
    else
      nil
    end
  end
end
