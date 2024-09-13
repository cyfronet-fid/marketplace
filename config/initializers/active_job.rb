# frozen_string_literal: true

ActiveJob::Base.queue_adapter = Rails.env.test? ? :test : :sidekiq
