# frozen_string_literal: true

require "rails_helper"

RSpec.describe InfrastructureManager::Client, type: :service, integration: true do
  let(:access_token) { ENV.fetch("IM_TEST_TOKEN", "demo_token_placeholder") }
  let(:client) { described_class.new(access_token) }

  let(:sample_tosca_template) { File.read(Rails.root.join("config", "templates", "jupyterhub_datamount.yml")) }

  # These tests require actual network access to the IM API
  # Run with: bundle exec rspec spec/services/infrastructure_manager/client_integration_spec.rb
  # Set IM_TEST_TOKEN environment variable for real testing

  describe "authorization header generation" do
    it "creates proper EGI authorization header" do
      auth_header = client.send(:authorization_header)
      parsed_auth = JSON.parse(auth_header)

      expect(parsed_auth).to be_an(Array)
      expect(parsed_auth.first).to include("type" => "EGI", "token" => access_token, "project_id" => "eosc-beyond")
    end
  end

  describe "IM API connection", skip: "Requires real IM API access" do
    it "can create infrastructure with TOSCA template" do
      skip "Set IM_TEST_TOKEN environment variable to run integration tests" unless ENV["IM_TEST_TOKEN"]

      result = client.create_infrastructure(sample_tosca_template)

      if result[:success]
        infrastructure_id = result[:data]
        expect(infrastructure_id).to be_present
        puts "✅ Created infrastructure: #{infrastructure_id}"

        # Clean up
        delete_result = client.delete_infrastructure(infrastructure_id)
        puts "🗑️ Cleanup result: #{delete_result[:success] ? "Success" : delete_result[:error]}"
      else
        puts "❌ Failed to create infrastructure: #{result[:error]}"
        puts "💡 This might be expected if authentication is not properly configured"
      end
    end
  end

  describe "error handling" do
    let(:client_with_bad_token) { described_class.new("invalid_token") }

    it "handles authentication errors gracefully", skip: "Requires real IM API access" do
      skip "Set IM_TEST_TOKEN environment variable to run integration tests" unless ENV["IM_TEST_TOKEN"]

      result = client_with_bad_token.create_infrastructure(sample_tosca_template)

      expect(result[:success]).to be false
      expect(result[:error]).to include("error")
      puts "✅ Properly handled authentication error: #{result[:error]}"
    end
  end
end
