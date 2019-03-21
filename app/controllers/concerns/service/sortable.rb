# frozen_string_literal: true

module Service::Sortable
  extend ActiveSupport::Concern

  private
    def ordering
      {}.tap do |sort_options|
        sort_key = params[:sort]
        unless params[:sort].blank?
          if sort_key[0] == "-"
            sort_key = sort_key[1..-1]
            sort_options[sort_key] = :desc
          else
            sort_options[sort_key] = :asc
          end
        else
          if params[:q].present?
            return
          else
            sort_options[:title] = :asc
          end
        end
      end
    end
end
