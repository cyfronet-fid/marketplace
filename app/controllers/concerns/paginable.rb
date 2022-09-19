# frozen_string_literal: true

module Paginable
  extend ActiveSupport::Concern

  private

  def paginate(records)
    records.paginate(page: params[:page], per_page: per_page)
  end

  def per_page(additionals_size = 0)
    per_page = (params[:per_page] || 10).to_i
    per_page -= additionals_size
    per_page < 1 ? 10 : per_page
  end
end
