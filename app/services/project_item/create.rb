# frozen_string_literal: true

class ProjectItem::Create
  def initialize(project_item, message = nil, bundle_params: nil)
    @project_item = project_item
    @message = message
    @bundle_params = bundle_params.respond_to?(:[]) ? bundle_params : {}
  end

  def call
    rolled_back = false
    bundled_project_items = []

    ProjectItem.transaction do
      if !@project_item.update(status: "created", status_type: :created)
        rolled_back = true
        raise ActiveRecord::Rollback
      end

      if @project_item&.offer.bundle?
        bundled_project_items = @project_item.offer.bundled_offers.map do |offer|
          ProjectItem.create(status: "created",
                             status_type: :created,
                             parent_id: @project_item.id,
                             project_id: @project_item.project_id,
                             offer_id: offer.id,
                             properties: @bundle_params[offer.id] || [])
        end

        if bundled_project_items.any? { |pi| !pi.persisted? }
          rolled_back = true
          raise ActiveRecord::Rollback
        end
      end
    end

    if !rolled_back
      ([@project_item] + bundled_project_items).each do |project_item|
        if orderable?(project_item)
          ProjectItem::RegisterJob.perform_later(project_item, @message)
          ProjectItemMailer.created(project_item).deliver_later
        else
          ProjectItem::ReadyJob.perform_later(project_item, @message)
          ProjectItemMailer.added_to_project(project_item).deliver_later
        end
      end
    end

    @project_item
  end

  private
    def orderable?(project_item)
      project_item.offer.orderable?
    end
end
