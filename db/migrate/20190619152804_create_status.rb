class CreateStatus < ActiveRecord::Migration[5.2]
  def change
    create_table :statuses do |t|
      t.belongs_to :author
      t.string :status
      t.text :message
      t.references :pipeline, polymorphic: true, index: true

      t.timestamps
    end
  end
end
