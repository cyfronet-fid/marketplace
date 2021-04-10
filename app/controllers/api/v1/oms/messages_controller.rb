# frozen_string_literal: true

class Api::V1::Oms::MessagesController < Api::V1::Oms::ApiController
  before_action :transform_params, only: [:create, :update]
  before_action :validate_payload, only: [:create, :update]
  before_action :find_project, only: [:index, :create]
  before_action :find_project_item, only: [:index, :create]
  before_action :find_and_authorize, only: :update

  def index
    # TODO: Obfuscate message content if scope == :user_direct
    @from_id = params[:from_id].present? ? params[:from_id] : 0
    @limit = params[:limit].present? ? params[:limit] : 20
    load_messages
    render json: { messages: @messages.map { |m| OrderingApi::V1::MessageSerializer.new(m) } }
  end

  def create
    attrs = permitted_attributes(Message)
    message = Message.new(
      author_email: attrs[:author][:email],
      author_name: attrs[:author][:name],
      author_role: attrs[:author][:role],
      scope: attrs[:scope],
      message: attrs[:content],
      messageable: @project_item.present? ? @project_item : @project
    )

    if Message::Create.new(message).call
      render json: OrderingApi::V1::MessageSerializer.new(message).as_json, status: 201
    else
      render json: { error: message.errors.messages }, status: 400
    end
  end

  def update
    if Message::Update.new(@message, { message: permitted_attributes(@message)[:content] }).call
      render json: OrderingApi::V1::MessageSerializer.new(@message).as_json
    else
      render json: { error: @message.errors.messages }, status: 400
    end
  end

  private
    def find_project
      p_id = (action_name == "index") ? params[:project_id] : permitted_attributes(Message)[:project_id]
      @project = @oms.associated_projects.find(p_id)
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Project not found" }, status: 404
    end

    def find_project_item
      if (action_name == "index") && params[:project_item_id].present?
        @project_item = @project.project_items.find_by!(iid: params[:project_item_id])
      elsif (action_name == "create") && permitted_attributes(Message)[:project_item_id].present?
        @project_item = @project.project_items.find_by!(iid: permitted_attributes(Message)[:project_item_id])
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Project item not found" }, status: 404
    end

    def load_messages
      messages = @project_item.present? ? @project_item.messages : @project.messages
      @messages = policy_scope(messages).where("id > ?", @from_id).order(:id).limit(@limit)
    end

    def validate_payload
      schema_file = (action_name == "create") ? "message_write.json" : "message_update.json"
      JSON::Validator.validate!(
        Rails.root.join("swagger", "v1", "ordering", "message", schema_file).to_s,
        params["message"].as_json
      )
    rescue JSON::Schema::ValidationError => e
      render json: { error: e.message }, status: 400
    end

    def find_and_authorize
      @message = Message.find(params[:id])
      authorize @message
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Message not found" }, status: 404
    end

    def transform_params
      params[:message][:project_id] = params[:project_id] if params[:project_id].present?
      params[:message][:project_item_id] = params[:project_item_id] if params[:project_item_id].present?
      params[:message][:author] = params[:author] if params[:author].present?
      params[:message][:content] = params[:content] if params[:content].present?
    end
end
