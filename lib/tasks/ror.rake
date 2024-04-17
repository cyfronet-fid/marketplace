# frozen_string_literal: true
require 'yajl/ffi'
require 'uri'
require 'net/http'
require 'rubygems'
require 'zip'


namespace :ror do
    desc "Organisations ROR data"

    destination_path = File.join(Rails.root, '/tmp/ror/')
    zenodo_url = URI("https://zenodo.org/api/communities/ror-data/records?q=&sort=newest")

    task add_rors: :environment do
        zip_data = get_recet_zip_data(zenodo_url)
        zip_file_path = download_zip_file(zip_data, destination_path)
        json_file = extract_json(zip_file_path, destination_path)
        seed_db(json_file)
    end

    task add_dev_rors: :environment do
        seed_db("db/ror-short.json")
    end
end


def get_recet_zip_data(zenodo_url)
    puts "Getting url of the recent ROR data dump..."
    zenodo_response = Net::HTTP.get_response(zenodo_url)
    case zenodo_response
        when Net::HTTPSuccess then
            zenodo_response
        else
            Rails.logger.warn "ERROR[ROR] - Downloading zip data from zenodo.org failed" 
        end
    unless zenodo_response
        return
    end
    begin
        parsed = JSON.parse(zenodo_response.body)
    rescue JSON::ParserError => e
        Rails.logger.warn "ERROR[ROR] - Parsing json form zenodo.org failed: #{e}"
        return
    end
    begin
        target_path = parsed['hits']['hits'][0]['files'][0]['links']['self']
        zip_filename = parsed['hits']['hits'][0]['files'][0]['key']
    rescue NoMethodError => e
        Rails.logger.warn "ERROR[ROR] - Json form zenodo.org schema changed: #{e}"
        return
    end
    puts "Path to recent zip file successfully downloaded"
    {
        path: target_path,
        filename: zip_filename
    }
end


def download_zip_file(zip_data, destination_path)
    puts "Downloading zip file..."
    Dir.mkdir destination_path
    destination_zip_file = File.join(destination_path, zip_data[:filename])
    target_url = URI(zip_data[:path])
    Net::HTTP.start(target_url.host, target_url.port, :use_ssl => true) do |http|
        req = Net::HTTP::Get.new target_url.path
        http.request req do |response|
            open destination_zip_file, "w" do |io|
                response.read_body do |chunk|
                    io.write chunk.force_encoding('UTF-8')
                end
            end
        end
    end
    puts "Zip file successfully downloaded"
    destination_zip_file
end

def extract_json(zip_file_path, destination_path)
    puts "Extracting json from the downloaded zip..."
    Zip::File.open(zip_file_path) do |zip_file|
        zip_file.each do |entry| 
            if entry.name.include? "data.json" 
                destination_json_file = File.join(destination_path, entry.name)
                zip_file.extract(entry, destination_json_file) unless File.exist?(destination_json_file) # TODO log in data didn't change
                puts "Json successfully extracted"
                return destination_json_file
            end
        end
    end
end

def seed_db(json_file)
    puts "Seeding db with organisations ROR data..."
    stream = File.open(json_file)
        parsed_data = Yajl::FFI::Parser.parse(stream)

        parsed_data.each do |obj|
            begin
                Raid::Ror.create!(pid: obj['id'], name: obj['name'], aliases: obj['aliases'], acronyms: obj['acronyms'])
            rescue ActiveRecord::RecordNotUnique
                next
            end
        end
    puts "RORs successfully saved into db"
 end
