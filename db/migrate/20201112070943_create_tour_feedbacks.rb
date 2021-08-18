# frozen_string_literal: true

class CreateTourFeedbacks < ActiveRecord::Migration[6.0]
  def change
    create_table :tour_feedbacks do |t|
      t.string :controller_name, index: true
      t.string :action_name, index: true
      t.string :tour_name, index: true
      t.belongs_to :user, foreign_key: true, null: true, index: true
      t.string :email, null: true, index: true
      t.json :content
      t.timestamps
    end
  end
end
