# frozen_string_literal: true
class AddDeployableServiceToOffers < ActiveRecord::Migration[7.2]
  def change
    add_reference :offers, :deployable_service, null: true, foreign_key: true
  end
end
