# frozen_string_literal: true

class ProjectItem::Create
  def initialize(project_item, message = nil, bundle_params: nil)
    @project_item = project_item
    @project = project_item.project
    @message = message
    @bundle_params = bundle_params.respond_to?(:[]) ? bundle_params : {}
  end

  def call
    rolled_back = false
    bundled_project_items = []

    ProjectItem.transaction do
      unless @project_item.update(status: "created", status_type: :created)
        rolled_back = true
        raise ActiveRecord::Rollback
      end

      if @project_item&.offer.bundle?
        bundled_project_items =
          @project_item.offer.bundled_offers.map do |offer|
            bundled_parameters =
              if @bundle_params.respond_to?(:has_key?) && @bundle_params&.key?(offer.id)
                @bundle_params[offer.id].map(&:to_json)
              else
                []
              end
            ProjectItem.create(
              status: "created",
              status_type: :created,
              parent_id: @project_item.id,
              project_id: @project.id,
              offer_id: offer.id,
              properties: bundled_parameters
            )
          end

        if bundled_project_items.any? { |pi| pi.nil? || !pi.persisted? }
          rolled_back = true
          raise ActiveRecord::Rollback
        end
      end
    end

    unless rolled_back
      persisted_project_items = [@project_item] + bundled_project_items

      persisted_project_items.each do |project_item|
        if orderable?(project_item)
          ProjectItem::RegisterJob.perform_later(project_item, @message)
          ProjectItemMailer.created(project_item).deliver_later
        else
          ProjectItem::ReadyJob.perform_later(project_item, @message)
          ProjectItemMailer.added_to_project(project_item).deliver_later
        end
      end

      updated_project = Project.find_by(id: @project.id)
      ProjectItem::OnCreated::PublishAddition.call(updated_project, persisted_project_items)
      ProjectItem::OnCreated::PublishCoexistence.call(updated_project)
    end

    @project_item
  end

  private

  def orderable?(project_item)
    project_item.offer.orderable?
  end
end
