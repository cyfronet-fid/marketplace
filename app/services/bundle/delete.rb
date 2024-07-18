# frozen_string_literal: true

class Bundle::Delete < Bundle::ApplicationService
  def call
    copy = @bundle.dup
    @bundle.status = :deleted
    result = @bundle&.project_items.present? ? @bundle.save!(validate: false) : @bundle.destroy!
    @bundle = copy
    notify_unbundled! if result
    @bundle.service.reindex
    result
  end
end
