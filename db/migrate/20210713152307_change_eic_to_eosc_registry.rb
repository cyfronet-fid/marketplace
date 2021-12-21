# frozen_string_literal: true

class ChangeEicToEoscRegistry < ActiveRecord::Migration[6.0]
  def up
    execute(<<~SQL)
      UPDATE service_sources
      SET source_type = CASE
        WHEN source_type='eic' THEN 'eosc_registry'
      END;
    SQL

    execute(<<~SQL)
      UPDATE provider_sources
      SET source_type = CASE
        WHEN source_type='eic' THEN 'eosc_registry'
      END;
    SQL
  end

  def down
    execute(<<~SQL)
      UPDATE service_sources
      SET source_type = CASE
        WHEN source_type='eosc_registry' THEN 'eic'
      END;
    SQL

    execute(<<~SQL)
      UPDATE provider_sources
      SET source_type = CASE
        WHEN source_type='eosc_registry' THEN 'eic'
      END;
    SQL
  end
end
