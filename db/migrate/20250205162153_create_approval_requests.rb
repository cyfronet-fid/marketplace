# frozen_string_literal: true

class CreateApprovalRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :approval_requests do |t|
      t.belongs_to :approvable, polymorphic: true, index: true
      t.belongs_to :user, index: true
      t.string :last_action
      t.string :status
      t.datetime :conversation_last_seen

      t.timestamps
    end
  end
end
