class AddStatusToService < ActiveRecord::Migration[5.2]
  def up
    add_column :services, :status, :string

    Service.find_each do |service|
      service.status = "published"
      service.save!
    end
  end

  def down
    remove_column :services, :status
  end
end
