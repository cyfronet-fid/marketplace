# frozen_string_literal: true

class Test::ThreadTimeTestJob < ApplicationJob
  def perform
    puts "Perform 30 seconds job in queue #{queue_name}"
    sleep(30)
    puts "ThreadTimeTestJob completed."
  end
end
