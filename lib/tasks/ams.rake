# frozen_string_literal: true

namespace :ams do
  desc "Create AMS subscriptions for all configured topics. Set DRY_RUN=true to only print what would be created."
  task create_subscriptions: :environment do
    config = Rails.application.config_for(:ams)

    if config.subscription_prefix.blank?
      puts "AMS subscription_prefix is not configured, aborting"
      next
    end

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false))
    client = Ams::Client.new

    config.topics.each do |topic_name|
      subscription_name = "#{config.subscription_prefix}-#{topic_name}"

      if dry_run
        puts "[dry run] Would create subscription #{subscription_name}"
        next
      end

      puts "Creating subscription #{subscription_name}"
      response = client.create_subscription(topic_name)
      puts "  -> #{response.status}"
    end
  end

  desc "Delete AMS subscriptions for all configured topics. Set DRY_RUN=true to only print what would be deleted."
  task delete_subscriptions: :environment do
    config = Rails.application.config_for(:ams)

    if config.subscription_prefix.blank?
      puts "AMS subscription_prefix is not configured, aborting"
      next
    end

    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", false))
    client = Ams::Client.new

    config.topics.each do |topic_name|
      subscription_name = "#{config.subscription_prefix}-#{topic_name}"

      if dry_run
        puts "[dry run] Would delete subscription #{subscription_name}"
        next
      end

      puts "Deleting subscription #{subscription_name}"
      response = client.delete_subscription(topic_name)
      puts "  -> #{response.status}"
    end
  end
end
