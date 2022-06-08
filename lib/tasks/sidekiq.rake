# frozen_string_literal: true

namespace :sidekiq do
  desc "Test for concurency of threads in the sidekiq queue"

  task thread_test: :environment do
    5.times do
      Test::ThreadTimeTestJob.set(queue: :default).perform_later
      Test::ThreadTimeTestJob.set(queue: :pc_subscriber).perform_later
    end
  end
end
