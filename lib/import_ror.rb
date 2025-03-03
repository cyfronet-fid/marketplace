# frozen_string_literal: true

require "yajl/ffi"
require "uri"
require "net/http"
require "rubygems"
require "zip"

class ImportRor
  def initialize
    @destination_path = File.join(Rails.root, "/tmp/ror/")
    @zenodo_url = URI("https://zenodo.org/api/communities/ror-data/records?q=&sort=newest")
    @json_file = File.join(Rails.root, "db/ror-short.json")
  end

  class DumpAlreadyProcessedError < StandardError
  end

  class NewDumpDataError < StandardError
  end

  def create_ror_data
    zip_data = recent_zip_data
    zip_file_path = download_zip_file(zip_data)
    json_file = extract_json(zip_file_path)
    seed_db(json_file)
  rescue DumpAlreadyProcessedError
    puts "The most recent dump is already proccessed"
  rescue NewDumpDataError
    puts "Error occured. Exiting"
  end

  def create_dev_ror_data
    seed_db
  end

  def recent_zip_data
    puts "Getting url of the recent ROR data dump..."
    zenodo_response = Net::HTTP.get_response(@zenodo_url)
    case zenodo_response
    when Net::HTTPSuccess
      zenodo_response
    else
      Rails.logger.warn "ERROR[ROR] - Downloading zip data from zenodo.org failed"
      raise NewDumpDataError(zenodo_response.message)
    end
    begin
      parsed = JSON.parse(zenodo_response.body)
    rescue JSON::ParserError => e
      Rails.logger.warn "ERROR[ROR] - Parsing json form zenodo.org failed: #{e}"
      raise NewDumpDataError(e)
    end
    begin
      target_path = parsed["hits"]["hits"][0]["files"][0]["links"]["self"]
      zip_filename = parsed["hits"]["hits"][0]["files"][0]["key"]
    rescue NoMethodError => e
      Rails.logger.warn "ERROR[ROR] - Json form zenodo.org schema changed: #{e}"
      raise NewDumpDataError(e)
    end
    check_exisitng_data(zip_filename)
    puts "Path to recent zip file successfully downloaded"
    { path: target_path, filename: zip_filename }
  end

  def check_exisitng_data(filename)
    json_filename = filename.sub "zip", "json"
    raise DumpAlreadyProcessedError if File.exist?(File.join(@destination_path, json_filename))
  end

  def download_zip_file(zip_data)
    puts "Downloading zip file..."
    Dir.mkdir @destination_path unless File.directory?(@destination_path)
    destination_zip_file = File.join(@destination_path, zip_data[:filename])
    target_url = URI(zip_data[:path])
    Net::HTTP.start(target_url.host, target_url.port, use_ssl: true) do |http|
      req = Net::HTTP::Get.new target_url.path
      http.request req do |response|
        File.open destination_zip_file, "w" do |io|
          response.read_body { |chunk| io.write chunk.force_encoding("UTF-8") }
        end
      end
    rescue StandardError => e
      Rails.logger.warn "ERROR[ROR] - Dowloading zip file form zenodo.org failed: #{e}"
      raise NewDumpDataError("Downloading zip failed: #{e}")
    end
    puts "Zip file successfully downloaded"
    destination_zip_file
  end

  def extract_json(zip_file_path)
    puts "Extracting json from the downloaded zip..."
    Zip::File.open(zip_file_path) do |zip_file|
      zip_file.each do |entry|
        next unless entry.name.include? "data.json"
        destination_json_file = File.join(@destination_path, entry.name)
        zip_file.extract(entry, destination_json_file)
        puts "Json successfully extracted"
        return destination_json_file
      end
    rescue StandardError => e
      Rails.logger.warn "ERROR[ROR] - Extracting json failed: #{e}"
      raise NewDumpDataError("Extracting json failed: #{e}")
    end
  end

  def seed_db(json_file = @json_file)
    puts "Seeding db with organisations ROR data..."
    stream = File.open(json_file)
    parsed_data = Yajl::FFI::Parser.parse(stream)
    parsed_data.each do |obj|
      Raid::Ror.create!(pid: obj["id"], name: obj["name"], aliases: obj["aliases"], acronyms: obj["acronyms"])
    rescue ActiveRecord::RecordNotUnique
      next
    end
    puts "RORs successfully saved into db"
  end
end
