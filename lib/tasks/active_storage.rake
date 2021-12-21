# frozen_string_literal: true

def migrate(from, to)
  # IMPORTANT!!!
  # without including Blob, migration from local to s3 may not work
  # rubocop:disable Lint/Void
  ActiveStorage::Blob

  # rubocop:enable Lint/Void

  configs = Rails.configuration.active_storage.service_configurations
  source = ActiveStorage::Service.configure from, configs
  target = ActiveStorage::Service.configure to, configs

  ActiveStorage::Blob.service = source

  puts "#{ActiveStorage::Blob.count} Blobs: "

  ActiveStorage::Blob.find_each do |blob|
    blob.open do |file|
      print "."
      target.upload(blob.key, file, checksum: blob.checksum)
    end
  rescue Errno::ENOENT
    puts "Rescued by Errno::ENOENT statement. ID: #{blob.id} / Key: #{blob.key}"
    next
  rescue ActiveStorage::FileNotFoundError
    puts "Rescued by FileNotFoundError. ID: #{blob.id} / Key: #{blob.key}"
    next
  end
end

namespace :storage do
  desc "Migrate ActiveStorage files from local to Ceph"
  task upload_to_s3: :environment do
    migrate(:local, :s3)
  end

  desc "Migrate ActiveStorage files from s3 to local"
  task upload_to_local: :environment do
    migrate(:s3, :local)
  end
end
