# frozen_string_literal: true

class AddServiceOpinionCount < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :service_opinion_count, :integer, default: 0
  end
end
