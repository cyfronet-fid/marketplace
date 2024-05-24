# frozen_string_literal: true

namespace :ror do
  desc "Organisations ROR data"

  @destination_path = File.join(Rails.root, "/tmp/ror/")
  @zenodo_url = URI("https://zenodo.org/api/communities/ror-data/records?q=&sort=newest")

  task add_rors: :environment do
    ImportRor.new.create_ror_data
  end

  task add_dev_rors: :environment do
    ImportRor.new.create_dev_ror_data
  end
end
