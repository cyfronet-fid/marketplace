# frozen_string_literal: true

class ChangeOffersParametersDefault < ActiveRecord::Migration[5.2]
  def up
    change_column :offers, :parameters, :jsonb, default: [], null: false
  end

  def down
    change_column :offers, :parameters, :jsonb, default: nil, null: true
  end
end
