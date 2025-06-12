# frozen_string_literal: true

module StatusChangeHelper
  ACTIONS = { Publish: "Publish", Suspend: "Suspend", Unpublish: "Unpublish" }.freeze

  def action_for(object, action)
    "#{object.class}::#{ACTIONS[action.to_sym]}".constantize
  end
end
