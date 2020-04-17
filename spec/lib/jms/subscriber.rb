# frozen_string_literal: true

require "rails_helper"
require "jms/subscriber"

describe Jms::Subscriber do
  let(:host) { "docker-fid.grid.cyf-kr.edu.pl"}
  let(:destination) { "mp_test" }
  let(:jms_subscriber) { double("Jms::Subscriber", destination, host) }

  it "should recive message" do
    response = create(:jms_response)
    expect(jms_subscriber).to receive(:run).with(response)
  end
end
