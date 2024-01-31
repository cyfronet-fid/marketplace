# frozen_string_literal: true

class RewriteContactEmailsToPublicContacts < ActiveRecord::Migration[6.0]
  def up
    services = execute("SELECT * FROM services")
    services.each do |service|
      emails = service["contact_emails"].tr("{}", "").split(",").map
      emails.each { |email| execute(<<~SQL) }
          INSERT INTO contacts(email, type, contactable_id, contactable_type, created_at, updated_at)
          VALUES ('#{email}', 'PublicContact', '#{service["id"]}', 'Service', '#{Time.now}', '#{Time.now}')
          RETURNING id
          SQL
    end
  end

  def down
    services = execute("SELECT * FROM services")
    services.each do |service|
      emails_query = execute("SELECT * FROM contacts WHERE contacts.contactable_id = #{service["id"]}")
      emails = emails_query.map { |e| e["email"] }.to_s.tr("[]", "{}").tr("\"", "")
      execute(<<~SQL)
        UPDATE services SET contact_emails = '#{emails}' WHERE id = '#{service["id"]}'
        SQL
    end
  end
end
