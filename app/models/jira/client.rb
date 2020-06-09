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

  class JIRAProjectIssueUpdateError < JIRAIssueCreateError
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
  attr_reader :wf_todo_id, :wf_in_progress_id, :wf_done_id,
              :wf_rejected_id, :wf_waiting_for_response_id,
              :wf_closed_id, :wf_ready_id, :wf_approved_id,
              :wf_archived_id

  def initialize
    # read required options and initialize jira client
    @jira_config = Mp::Application.config_for(:jira)
    @webhook_secret = @jira_config[:webhook_secret]

    options = {
        username: @jira_config[:username],
        password: @jira_config[:password],
        site: @jira_config[:url],
        context_path: @jira_config[:context_path],
        auth_type: :basic,
        use_ssl: (/^https\:\/\// =~ @jira_config[:url])
    }

    @jira_project_key = @jira_config[:project]
    @jira_issue_type_id = @jira_config[:issue_type_id]
    @jira_project_issue_type_id = @jira_config[:project_issue_type_id]

    @wf_todo_id = @jira_config[:workflow][:todo]
    @wf_in_progress_id = @jira_config[:workflow][:in_progress]
    @wf_rejected_id = @jira_config[:workflow][:rejected]
    @wf_waiting_for_response_id = @jira_config[:workflow][:waiting_for_response]
    @wf_closed_id = @jira_config[:workflow][:closed]
    @wf_ready_id = @jira_config[:workflow][:ready]
    @wf_approved_id = @jira_config[:workflow][:approved]
    @wf_archived_id = @jira_config[:workflow][:archived]

    fields_config = @jira_config[:custom_fields]

    @custom_fields = {
      "Epic Link": fields_config["Epic Link".to_sym],
      "Epic Name": fields_config["Epic Name".to_sym],
      "Order reference": fields_config["Order reference".to_sym],
      "CI-Name": fields_config["CI-Name".to_sym],
      "CI-Surname": fields_config["CI-Surname".to_sym],
      "CI-Email": fields_config["CI-Email".to_sym],
      "CI-DisplayName": fields_config["CI-DisplayName".to_sym],
      "CI-EOSC-UniqueID": fields_config["CI-EOSC-UniqueID".to_sym],
      "CI-Institution": fields_config["CI-Institution".to_sym],
      "CI-Department": fields_config["CI-Department".to_sym],
      "CI-DepartmentalWebPage": fields_config["CI-DepartmentalWebPage".to_sym],
      "CI-SupervisorName": fields_config["CI-SupervisorName".to_sym],
      "CI-SupervisorProfile": fields_config["CI-SupervisorProfile".to_sym],
      "CP-CustomerCountry": fields_config["CP-CustomerCountry".to_sym],
      "CP-CustomerTypology": fields_config["CP-CustomerTypology".to_sym],
      "CP-CollaborationCountry": fields_config["CP-CollaborationCountry".to_sym],
      "CP-ReasonForAccess": fields_config["CP-ReasonForAccess".to_sym],
      "CP-UserGroupName": fields_config["CP-UserGroupName".to_sym],
      "CP-ProjectInformation": fields_config["CP-ProjectInformation".to_sym],
      "CP-ScientificDiscipline": fields_config["CP-ScientificDiscipline".to_sym],
      "CP-Platforms": fields_config["CP-Platforms".to_sym],
      "CP-INeedAVoucher": fields_config["CP-INeedAVoucher".to_sym],
      "CP-VoucherID": fields_config["CP-VoucherID".to_sym],
      # For now only single Service Offer is supported
      "SO-ProjectName": fields_config["SO-ProjectName".to_sym],
      "SO-1": fields_config["SO-1".to_sym],
      "SO-ServiceOrderTarget": fields_config["SO-ServiceOrderTarget".to_sym],
      "SO-OfferType": fields_config["SO-OfferType".to_sym]
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
                       "#{project_item.service.name}",
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

  def update_project_issue(project)
    unless project.jira_active?
      raise ProjectIssueDoesNotExist.new(project)
    end

    issue = self.Issue.find(project.issue_id)

    fields = { summary: "Project, #{project.user.first_name} " +
                       "#{project.user.last_name}, " +
                       "#{project.name}" }
    @custom_fields.reject { |k, v| v.empty? }.each do |field_name, field_id|
      value = generate_project_custom_field_value(field_name.to_s, project)
      unless value.nil?
        fields[field_id.to_s] = value
      end
    end

    if issue.save(fields: fields)
      issue
    else
      raise JIRAProjectIssueUpdateError.new(project, issue.errors)
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
      "category" => project_item.service.categories.first&.name,
      "service" => project_item.service.name,
      "offer" => project_item.name,
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
      project.email || nil
    when "CI-Institution"
      project.single_user_or_community? ? project.organization : nil
    when "CI-Department"
      project.single_user_or_community? ? project.department : nil
    when "CI-DepartmentalWebPage"
      project.single_user_or_community? ? URI.parse(project.webpage).to_s : nil
    when "CI-DisplayName"
      "#{project.user.first_name} #{project.user.last_name}"
    when "CP-ScientificDiscipline"
      project.scientific_domains .names.join(", ")
    when "CI-EOSC-UniqueID"
      project.user.uid
    when "CP-CustomerTypology"
      if project.customer_typology
        { "id" => @jira_config[:custom_fields][:select_values]["CP-CustomerTypology".to_sym][project.customer_typology.to_sym] }
      else
        nil
      end
    when "CP-CustomerCountry"
      project.country_of_origin&.name || "N/A"
    when "CP-CollaborationCountry"
      if project.countries_of_partnership&.present?
        project.countries_of_partnership&.map(&:name).join(", ")
      else
        "N/A"
      end
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
    #   project.scientific_domain&.name
    else
      nil
    end
  end

  def generate_project_item_custom_field_value(field_name, project_item)
    case field_name
    when "Order reference"
      if ENV["ROOT_URL"].blank?
        project_service_path(project_item.project, project_item)
      else
        project_service_url(project_item.project, project_item, host: ENV["ROOT_URL"])
      end
    when "Epic Link"
      project_item.project.issue_key
    when "CP-Platforms"
      project_item.offer.service.platforms.pluck(:name).join(", ")
    when "CP-INeedAVoucher"
      { "id" => @jira_config[:custom_fields][:select_values]["CP-INeedAVoucher".to_sym][project_item.request_voucher ? :yes : :no] }
    when "CP-VoucherID"
      project_item.voucher_id || nil
    when "SO-1"
      encode_order_properties(project_item)
    when "SO-ServiceOrderTarget"
      project_item.service.order_target
    when "SO-OfferType"
      { "id" => @jira_config[:custom_fields][:select_values]["SO-OfferType".to_sym][project_item.order_type.to_sym] }
    else
      nil
    end
  end
end
