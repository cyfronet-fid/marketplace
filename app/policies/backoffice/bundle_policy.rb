# frozen_string_literal: true

class Backoffice::BundlePolicy < Backoffice::OrderablePolicy
  def permitted_attributes
    [
      :id,
      :name,
      [bundle_goal_ids: []],
      [capability_of_goals_ids: []],
      :capability_of_goal_suggestion,
      :description,
      :order_type,
      :resource_organisation_id,
      [category_ids: []],
      [scientific_domain_ids: []],
      [target_user_ids: []],
      [research_activity_ids: []],
      :main_offer_id,
      :tag_list,
      :from,
      [offer_ids: []],
      :related_training,
      :related_training_url,
      :contact_email,
      :helpdesk_url,
      parameters_attributes: %i[
        type
        name
        hint
        min
        max
        unit
        value_type
        start_price
        step_price
        currency
        exclusive_min
        exclusive_max
        mode
        values
        value
      ]
    ]
  end
end
