# frozen_string_literal: true

class Api::V1::EventPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.default_oms_administrator?
        scope.all
      else
        # Outer join chosen events with ProjectItem OR Project OR Message eventables
        # and look if user is administrating an oms inside their respective offers.primary_oms
        scope
          .where("offers.primary_oms_id IN (?)", user.administrated_oms_ids)
          .or(scope.where("offers_project_items.primary_oms_id IN (?)", user.administrated_oms_ids))
          .or(scope.where("offers_project_items_2.primary_oms_id IN (?)", user.administrated_oms_ids))
          .or(scope.where("offers_project_items_3.primary_oms_id IN (?)", user.administrated_oms_ids))
          .left_outer_joins(
            { project_item: :offer },
            { project: { project_items: :offer } },
            { message: { project_item: :offer } },
            { message: { project: { project_items: :offer } } }
          )
          .distinct
      end
    end
  end
end
