# frozen_string_literal: true

class AddPublicContactEmailsToProviders < ActiveRecord::Migration[7.2]
  def up
    add_column :providers, :public_contact_emails, :string, array: true, default: []

    say_with_time "Backfilling public_contact_emails from public_contacts" do
      provider_class = Class.new(ActiveRecord::Base) { self.table_name = "providers" }
      contact_class = Class.new(ActiveRecord::Base) { self.table_name = "contacts" }

      contact_class
        .where(contactable_type: "Provider", type: "PublicContact")
        .where.not(email: [nil, ""])
        .pluck(:contactable_id, :email)
        .group_by(&:first)
        .each do |provider_id, rows|
          emails = rows.map { |(_, email)| email.to_s.strip }.reject(&:blank?).uniq
          provider_class.where(id: provider_id).update_all(public_contact_emails: emails)
        end
    end
  end

  def down
    remove_column :providers, :public_contact_emails
  end
end
