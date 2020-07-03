class RemovePhaseFromService < ActiveRecord::Migration[6.0]
  def up
    production = LifeCycleStatus.find_by(eid: "life_cycle_status-production")
    beta = LifeCycleStatus.find_by(eid: "life_cycle_status-beta")

    execute("SELECT phase, id FROM services").
      each { |d|
        if d["phase"] == "production"
          execute(
            <<~SQL
              INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
              VALUES ( #{d["id"]}, #{production.id}, 'LifeCycleStatus', '#{Time.now.to_s}', '#{Time.now.to_s}')
              SQL
          )
        elsif  d["phase"] == "beta"
          execute(
            <<~SQL
              INSERT INTO service_vocabularies(service_id, vocabulary_id, vocabulary_type, created_at, updated_at)
              VALUES ( #{d["id"]}, #{beta.id}, 'LifeCycleStatus', '#{Time.now.to_s}', '#{Time.now.to_s}')
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
