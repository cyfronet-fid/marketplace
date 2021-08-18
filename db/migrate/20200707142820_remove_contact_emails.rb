# frozen_string_literal: true

class RemoveContactEmails < ActiveRecord::Migration[6.0]
  def up
    remove_column :services, :contact_emails
  end

  def down
    add_column :services, :contact_emails, :text, array: true, default: []
  end
end
