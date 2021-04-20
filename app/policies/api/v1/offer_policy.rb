# frozen_string_literal: true

class Api::V1::OfferPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(status: :published).order(:iid)
    end
  end

  def show?
    published?
  end

  def create?
    true
  end

  def update?
    published?
  end

  def destroy?
    published?
  end

  def permitted_attributes
    [:name, :description, :webpage, :order_type, :order_url, :primary_oms_id,
     oms_params: {},
     parameters: [:id, :type, :label, :description, :unit, :value_type, :value,
                  config: [:mode, :minimum, :maximum, :minItems, :maxItems, :exclusiveMinimum,
                           :exclusiveMaximum, :start_price, :step_price, :currency, values: []
                   ]
      ]
    ]
  end

  private
    def published?
      record.status == "published"
    end
end
