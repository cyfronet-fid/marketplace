# frozen_string_literal: true

class AddEmailOrganizationDepartmentWebpageToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :email, :string
    add_column :projects, :organization, :string
    add_column :projects, :department, :string
    add_column :projects, :webpage, :string
  end
end
