class ChangeColumnNameForTitles < ActiveRecord::Migration[6.1]
  def change
    rename_column :titles, :title_type, :type
  end
end
