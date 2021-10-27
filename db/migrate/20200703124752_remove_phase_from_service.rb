# frozen_string_literal: true

class RemovePhaseFromService < ActiveRecord::Migration[6.0]
  def up
    production_id = execute(
      <<~SQL.squish
        INSERT INTO vocabularies(name, type, eid, created_at, updated_at)
        VALUES ('Production', 'LifeCycleStatus', 'life_cycle_status-production', '#{Date.now}', '#{Date.now}')
        RETURNING id;
      SQL
    )

    beta_id = execute(
      <<~SQL.squish
        INSERT INTO vocabularies(name, type, eid, created_at, updated_at)
        VALUES ('Beta', 'LifeCycleStatus', 'life_cycle_status-beta', '#{Date.now}', '#{Date.now}')
        RETURNING id;
      SQL
    )

    execute("SELECT phase, id FROM services")
      .each do |d|
        case d["phase"]
        when "production"
          execute(
            <<~SQL.squish
              INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
              VALUES ( #{d['id']}, #{production_id[0]['id']}, 'LifeCycleStatus', '#{Date.now}', '#{Date.now}')
            SQL
          )
        when "beta"
          execute(
            <<~SQL.squish
              INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
              VALUES ( #{d['id']}, #{beta_id[0]['id']}, 'LifeCycleStatus', '#{Date.now}', '#{Date.now}')
            SQL
          )
        end
      end
    remove_column :services, :phase
  end

  def down
    add_column :services, :phase, :string
  end
end
