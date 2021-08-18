# frozen_string_literal: true

class ChangeProjectDefaultTimestamp < ActiveRecord::Migration[6.0]
  def change
    change_column_default :projects, :created_at, nil
    change_column_default :projects, :updated_at, nil
  end
end
