# frozen_string_literal: true

class UpdateDeployableServicesToV6 < ActiveRecord::Migration[7.2]
  def up
    add_column :deployable_services, :publishing_date, :date
    add_column :deployable_services, :resource_type, :string
    add_column :deployable_services, :public_contact_emails, :string, array: true, default: []
    add_column :deployable_services, :license_name, :string
    add_column :deployable_services, :license_url, :string
    add_column :deployable_services, :urls, :string, array: true, default: []

    if column_exists?(:deployable_services, :software_license)
      execute "UPDATE deployable_services SET license_name = software_license WHERE license_name IS NULL"
    end

    remove_column :deployable_services, :software_license, :string, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
