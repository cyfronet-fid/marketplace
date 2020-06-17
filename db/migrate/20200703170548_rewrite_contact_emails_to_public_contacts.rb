class RewriteContactEmailsToPublicContacts < ActiveRecord::Migration[6.0]
  def up
    services = execute(("SELECT * FROM services"))
    services.each do |service|
      emails = service["contact_emails"].tr("{}", "").split(",").map
      emails.each do |email|
        execute(<<~SQL
          INSERT INTO service_contacts(email, service_id, type, created_at, updated_at)
          VALUES ('#{email}', '#{service["id"]}', 'PublicContact', '#{Time.now.to_s}', '#{Time.now.to_s}')
          RETURNING id
        SQL
        )
      end
    end
  end

  def down
    services = execute("SELECT * FROM services")
    services.each do |service|
      emails_query = execute("SELECT * FROM service_contacts WHERE service_contacts.service_id = #{service["id"]}")
      emails = emails_query.map { |e| e["email"]}.to_s.tr("[]", "{}").tr("\"", "")
      execute(<<~SQL
                UPDATE services SET contact_emails = '#{emails}' WHERE id = '#{service["id"]}'
              SQL
              )

    end
  end
end
