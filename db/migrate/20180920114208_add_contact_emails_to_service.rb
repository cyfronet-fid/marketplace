class AddContactEmailsToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :contact_emails, :text, array: true, default: []
  end
end
