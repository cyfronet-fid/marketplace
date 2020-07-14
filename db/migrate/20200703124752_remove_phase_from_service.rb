class RemovePhaseFromService < ActiveRecord::Migration[6.0]
  def up
    production_id = execute(
      <<~SQL
        INSERT INTO vocabularies(name, type, eid, created_at, updated_at)
        VALUES ('Production', 'LifeCycleStatus', 'life_cycle_status-production', '#{Time.now.to_s}', '#{Time.now.to_s}')
        RETURNING id;
      SQL
    )

    beta_id = execute(
      <<~SQL
        INSERT INTO vocabularies(name, type, eid, created_at, updated_at)
        VALUES ('Beta', 'LifeCycleStatus', 'life_cycle_status-beta', '#{Time.now.to_s}', '#{Time.now.to_s}')
        RETURNING id;
      SQL
    )

    execute("SELECT phase, id FROM services").
      each { |d|
        if d["phase"] == "production"
          execute(
            <<~SQL
              INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
              VALUES ( #{d["id"]}, #{production_id[0]["id"]}, 'LifeCycleStatus', '#{Time.now.to_s}', '#{Time.now.to_s}')
              SQL
          )
        elsif  d["phase"] == "beta"
          execute(
            <<~SQL
              INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
              VALUES ( #{d["id"]}, #{beta_id[0]["id"]}, 'LifeCycleStatus', '#{Time.now.to_s}', '#{Time.now.to_s}')
              SQL
          )
        end
      }
    remove_column :services, :phase
  end

  def down
    add_column :services, :phase, :string
  end
end
