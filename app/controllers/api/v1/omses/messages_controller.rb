# frozen_string_literal: true

class Api::V1::OMSes::MessagesController < Api::V1::ApplicationController
  before_action :find_and_authorize_oms
  before_action :find_and_authorize, only: %i[show update]
  before_action :prepare_params, only: %i[create update]
  before_action :validate_payload, only: %i[create update]
  before_action :validate_from_id, only: :index
  before_action :validate_limit, only: :index
  before_action :find_project, only: %i[index create]
  before_action :find_project_item, only: %i[index create]
  before_action :load_messages, only: :index

  def show
    render json: Api::V1::MessageSerializer.new(@message).as_json
  end

  def index
    render json: { messages: @messages.map { |m| Api::V1::MessageSerializer.new(m) } }
  end

  def create
    @message = message_template
    authorize @message

    if @message.save
      render json: Api::V1::MessageSerializer.new(@message, keep_content?: true).as_json, status: 201
    else
      render json: { error: @message.errors.to_hash }, status: 400
    end
  end

  def update
    if @message.update(transform(permitted_attributes(@message)))
      render json: Api::V1::MessageSerializer.new(@message, keep_content?: true).as_json
    else
      render json: { error: @message.errors.to_hash }, status: 400
    end
  end

  private

  def find_project
    p_id = action_name == "index" ? params[:project_id] : permitted_attributes(Message)[:project_id]
    @project = @oms.projects.find(p_id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: 404
  end

  def find_project_item
    if (action_name == "index") && params[:project_item_id].present?
      @project_item = @oms.project_items_for(@project).find_by!(iid: params[:project_item_id])
    elsif (action_name == "create") && permitted_attributes(Message)[:project_item_id].present?
      @project_item = @oms.project_items_for(@project).find_by!(iid: permitted_attributes(Message)[:project_item_id])
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project item not found" }, status: 404
  end

  def load_messages
    messages = @project_item.present? ? @project_item.messages : @project.messages
    @messages = policy_scope(messages).where("messages.id > ?", @from_id).order("messages.id").limit(@limit)
  end

  def find_and_authorize
    @message = @oms.messages.find(params[:id])
    authorize @message
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Message not found" }, status: 404
  end

  def prepare_params
    params[:message][:project_id] = params[:project_id] if params[:project_id].present?
    params[:message][:project_item_id] = params[:project_item_id] if params[:project_item_id].present?
    params[:message][:author] = params[:author] if params[:author].present?
    params[:message][:content] = params[:content] if params[:content].present?
  end

  def validate_payload
    schema_file = action_name == "create" ? "message_write.json" : "message_update.json"
    JSON::Validator.validate!(Rails.root.join("swagger", "v1", "message", schema_file).to_s, params[:message].as_json)
  rescue JSON::Schema::ValidationError => e
    render json: { error: e.message }, status: 400
  end

  def transform(attributes)
    transformed = {}
    if attributes[:author].present?
      transformed[:author_uid] = attributes[:author][:uid]
      transformed[:author_email] = attributes[:author][:email]
      transformed[:author_name] = attributes[:author][:name]
      transformed[:author_role] = attributes[:author][:role]
    end
    transformed[:scope] = attributes[:scope] if attributes[:scope].present?
    transformed[:message] = attributes[:content] if attributes[:content].present?
    transformed
  end

  def message_template
    temp = transform(permitted_attributes(Message))
    Message.new(temp.merge(messageable: @project_item.present? ? @project_item : @project))
  end
end
