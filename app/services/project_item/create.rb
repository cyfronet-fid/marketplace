# frozen_string_literal: true

class ProjectItem::Create < ApplicationService
  def initialize(project_item, message = nil, bundle_params: nil)
    super()
    @project_item = project_item
    @project = project_item.project
    @message = message
    @bundle_params = bundle_params.respond_to?(:[]) ? bundle_params : {}
    @offer = @project_item.offer
  end

  def call
    rolled_back = false
    bundled_project_items = []

    ProjectItem.transaction do
      status = @offer.orderable? ? "created" : "ready"
      unless @project_item.update(status: status, status_type: status)
        rolled_back = true
        raise ActiveRecord::Rollback
      end

      if @project_item&.bundle?
        bundled_project_items =
          @project_item.bundle.offers.map do |offer|
            bundled_parameters =
              if @bundle_params.respond_to?(:key?) && @bundle_params&.key?(offer.id)
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
              voucher_id: @project_item.voucher_id,
              request_voucher: @project_item.request_voucher,
              bundle_id: @project_item.bundle.id,
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
      non_customizable_project_item = ProjectItem.find_by(id: @project_item.id)
      persisted_project_items = [non_customizable_project_item] + bundled_project_items

      persisted_project_items.each do |project_item|
        if @offer.orderable?
          ProjectItem::RegisterJob.perform_later(project_item, @message)
          ProjectItemMailer.created(project_item).deliver_later
        else
          ProjectItem::ReadyJob.perform_later(project_item, @message)
          ProjectItemMailer.added_to_project(project_item).deliver_later
        end
      end

      updated_project = Project.find_by(id: @project.id)
      notify_providers
      ProjectItem::OnCreated::PublishAddition.call(updated_project, persisted_project_items)
      ProjectItem::OnCreated::PublishCoexistence.call(updated_project)
    end

    @project_item
  end

  private

  def notify_providers
    @offer.reload
    if @offer.limited_availability? && @offer.availability_count.zero?
      @offer
        .service
        .resource_organisation
        .data_administrators
        .map(&:user)
        .compact
        .each { |manager| OfferMailer.notify_provider(@offer, manager).deliver_later }
    end
  end
end
