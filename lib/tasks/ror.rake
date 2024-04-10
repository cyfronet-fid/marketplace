# frozen_string_literal: true

namespace :ror do
    desc "Organisations ROR data"


    task add_rors: :environment do
        data = File.read("db/ror-short.json")
        parsed_data = JSON.parse(data)

        parsed_data.each do |obj|
            Raid::Ror.create!(pid: obj['id'], name: obj['name'], aliases: obj['aliases'], acronyms: obj['acronyms'])
        end
    puts "Seeding db with organisations ROR data"
    end
end
