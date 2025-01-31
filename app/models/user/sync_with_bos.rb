# frozen_string_literal: true

class User::SyncWithBos
  def self.sync(user)
    user_params = { email: user.email, name: user.full_name, user_type: ["mp_user"] }

    response =
      Faraday.post("#{Mp::Application.config.bos_url}/users/") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = user_params.to_json
      end

    body = JSON.parse(response.body)
    Rails.logger.warn("User `#{user.email}` already exists in BOS.") if response.status == 409
    Rails.logger.error("Failed to sync user `#{user.email}` with BOS. Response: #{body}") if response.status != 200
  rescue StandardError => e
    Rails.logger.error("Failed to reach the BOS endpoint at #{Mp::Application.config.bos_url}: #{e.message}")
  end
end
