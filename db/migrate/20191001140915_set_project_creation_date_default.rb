# frozen_string_literal: true

class SetProjectCreationDateDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default :projects, :created_at, Time.zone.parse("1 Oct 2019 00:00:00")
    change_column_default :projects, :updated_at, Time.zone.parse("1 Oct 2019 00:00:00")
  end
end
