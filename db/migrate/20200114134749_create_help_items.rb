class CreateHelpItems < ActiveRecord::Migration[6.0]
  def change
    create_table :help_items do |t|
      t.string :title, nil: false
      t.string :slug, unique: true
      t.integer :position, nil: false, default: 0

      t.belongs_to :help_section, null: false

      t.timestamps
    end
  end
end
