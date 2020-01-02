# frozen_string_literal: true

module Paginable
  extend ActiveSupport::Concern

  private
    def paginate(records)
      records.paginate(page: params[:page], per_page: per_page)
    end

    def per_page
      per_page = params[:per_page].to_i
      per_page < 1 ? 10 : per_page
    end
end
