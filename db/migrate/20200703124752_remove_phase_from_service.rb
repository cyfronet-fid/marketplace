# frozen_string_literal: true

class RemovePhaseFromService < ActiveRecord::Migration[6.0]
  def up
    production_id = execute(<<~SQL)
        INSERT INTO vocabularies(name, type, eid, created_at, updated_at)
        VALUES ('Production', 'Vocabulary::LifeCycleStatus', 'life_cycle_status-production', '#{Time.now}', '#{Time.now}')
        RETURNING id;
      SQL

    beta_id = execute(<<~SQL)
        INSERT INTO vocabularies(name, type, eid, created_at, updated_at)
        VALUES ('Beta', 'Vocabulary::LifeCycleStatus', 'life_cycle_status-beta', '#{Time.now}', '#{Time.now}')
        RETURNING id;
      SQL

    execute("SELECT phase, id FROM services").each do |d|
      case d["phase"]
      when "production"
        execute(<<~SQL)
            INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
            VALUES ( #{d["id"]}, #{production_id[0]["id"]}, 'Vocabulary::LifeCycleStatus', '#{Time.now}', '#{Time.now}')
            SQL
      when "beta"
        execute(<<~SQL)
            INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
            VALUES ( #{d["id"]}, #{beta_id[0]["id"]}, 'Vocabulary::LifeCycleStatus', '#{Time.now}', '#{Time.now}')
            SQL
      end
    end
    remove_column :services, :phase
  end

  def down
    add_column :services, :phase, :string
  end
end
