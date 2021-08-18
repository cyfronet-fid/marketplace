# frozen_string_literal: true

class UpdateServicePhaseValues < ActiveRecord::Migration[5.2]
  def change
    execute("UPDATE services SET phase = 'discovery' where phase = 'Discovery (min. TRL 1)'")
    execute("UPDATE services SET phase = 'planned' where phase = 'Planned (min. TRL 3)'")
    execute("UPDATE services SET phase = 'alpha' where phase = 'Alpha (min. TRL 5)'")
    execute("UPDATE services SET phase = 'beta' where phase = 'Beta (min. TRL 7)'")
    execute("UPDATE services SET phase = 'production' where phase = 'Production (min. TRL 8)'")
    execute("UPDATE services SET phase = 'retired' where phase = 'Retired (n/a)'")
  end
end
