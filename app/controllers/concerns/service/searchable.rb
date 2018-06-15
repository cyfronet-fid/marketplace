# frozen_string_literal: true

module Service::Searchable
  extend ActiveSupport::Concern

  private

    def records
      params[:q].blank? ? Service.all : Service.where(id: search_ids)
    end

    def search_ids
      Service.search(params[:q]).records.ids
    end
end
