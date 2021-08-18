# frozen_string_literal: true

class UpdateNilParameters < ActiveRecord::Migration[5.2]
  def up
    execute("UPDATE offers set parameters = '[]' where parameters IS NULL;")
    execute("UPDATE project_items set properties = '[]' where properties IS NULL;")
  end
end
