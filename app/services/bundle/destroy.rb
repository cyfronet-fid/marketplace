# frozen_string_literal: true

class Bundle::Destroy < Bundle::ApplicationService
  def call
    result = @bundle&.project_items.present? ? @bundle.update(status: :deleted) : @bundle.destroy
    notify_unbundled! if result
    @bundle.service.reindex
    result
  end
end
