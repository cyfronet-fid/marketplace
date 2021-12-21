# frozen_string_literal: true

class AddAdditionalInformationToProject < ActiveRecord::Migration[5.2]
  def up
    add_column :projects, :additional_information, :text

    execute(
      "UPDATE projects SET additional_information = ( SELECT additional_information
            FROM project_items WHERE projects.id = project_items.project_id AND
            NOT ( additional_information IS NULL OR additional_information = '' ) LIMIT 1 )"
    )
  end

  def down
    remove_column :projects, :additional_information, :text
  end
end
