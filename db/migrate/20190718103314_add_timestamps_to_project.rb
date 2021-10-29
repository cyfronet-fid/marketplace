# frozen_string_literal: true

class AddTimestampsToProject < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :projects, default: Time.zone.now
  end
end
