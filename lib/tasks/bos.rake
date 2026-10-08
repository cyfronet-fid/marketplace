# frozen_string_literal: true

namespace :bos do
  desc "Sync all users with BOS"
  task sync_users: :environment do
    client = Bos::Client.new

    User.find_each do |user|
      puts "Syncing user: #{user.email}"
      client.create_user(user)
      puts "Synced #{user.email}"
    rescue StandardError => e
      puts "Failed to sync user #{user.email}: #{e.message}"
    end
  end

  desc "Sync all providers with BOS"
  task sync_providers: :environment do
    client = Bos::Client.new

    Provider.find_each do |provider|
      puts "Syncing provider: #{provider.name}"
      client.create_provider(provider)
      puts "Synced #{provider.name}"
    rescue StandardError => e
      puts "Failed to sync provider #{provider.name}: #{e.message}"
    end
  end
end
