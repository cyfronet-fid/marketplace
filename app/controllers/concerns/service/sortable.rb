# frozen_string_literal: true

module Service::Sortable
  extend ActiveSupport::Concern

  private

  def order(scope)
    params[:q].present? && params[:sort].blank? ? scope : scope.order(ordering)
  end

  def ordering
    {}.tap do |sort_options|
      sort_key = params[:sort]
      unless sort_key.blank?
        if sort_key == "_score"
          return
        elsif sort_key[0] == "-"
          sort_key = sort_key[1..]
          sort_options[sort_key] = :desc
        else
          sort_options[sort_key] = :asc
        end
      else
        sort_options[:sort_name] = :asc
      end
    end
  end
end
