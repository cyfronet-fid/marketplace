# frozen_string_literal: true

module Service::Sortable
  extend ActiveSupport::Concern

  private
    def order(scope)
      if params[:q].present? && params[:sort].blank?
        scope
      else
        scope.order(ordering)
      end
    end

    def ordering
      {}.tap do |sort_options|
        sort_key = params[:sort]
        unless sort_key.blank?
          if sort_key == "_score"
            return
          else
            if sort_key[0] == "-"
              sort_key = sort_key[1..-1]
              sort_options[sort_key] = :desc
            else
              sort_options[sort_key] = :asc
            end
          end
        else
          sort_options[:title] = :asc
        end
      end
    end
end
