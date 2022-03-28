# frozen_string_literal: true

require "rails_helper"
require "bcrypt"

RSpec.describe UserActionController, type: :controller do
  let(:user_action_params) do
    { timestamp: "now", target: "/xd", source: { root: { service_id: "/xd" } }, action: "click" }
  end

  before(:each) { allow(Mp::Application.config).to receive(:recommender_host).and_return("localhost") }

  it "sends a probe and jms publish jobs if user_actions_target is set to all" do
    allow(Mp::Application.config).to receive(:user_actions_target).and_return("all")

    expect(Jms::PublishJob).to receive(:perform_later).with(any_args, :databus)
    expect(Probes::ProbesJob).to receive(:perform_later)

    post :create, params: user_action_params
  end

  it "sends a Probes (recommender) job only if user_actions_target is set to recommender" do
    allow(Mp::Application.config).to receive(:user_actions_target).and_return("recommender")

    expect(Jms::PublishJob).not_to receive(:perform_later)
    expect(Probes::ProbesJob).to receive(:perform_later)

    post :create, params: user_action_params
  end

  it "sends a JMS (databus) job only if user_actions_target is set to databus" do
    allow(Mp::Application.config).to receive(:user_actions_target).and_return("databus")

    expect(Jms::PublishJob).to receive(:perform_later).with(any_args, :databus)
    expect(Probes::ProbesJob).not_to receive(:perform_later)

    post :create, params: user_action_params
  end

  # TODO: write tests regarding proper request_body JSON sent to JMS and Recommender
end
