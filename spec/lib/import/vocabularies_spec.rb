# frozen_string_literal: true

require "rails_helper"
require "jira/setup"

describe Import::Providers do
  let(:test_url) { "https://localhost/api" }
  let(:unirest) { double(Unirest) }

  def make_and_stub_eosc_registry(dry_run: false, filepath: nil, log: false)
    options = {
      dry_run: dry_run,
      filepath: filepath,
      unirest: unirest
    }

    unless log
      options[:logger] = ->(_msg) { }
    end

    Import::Vocabularies.new(test_url, options)
  end

  let(:eosc_registry) { make_and_stub_eosc_registry(log: true) }
  let(:log_less_eosc_registry) { make_and_stub_eosc_registry(log: false) }

  def expect_responses(unirest, test_url, vocabularies_response = nil)
    unless vocabularies_response.nil?
      expect(unirest).to receive(:get).with("#{test_url}/vocabulary/byType/",
                                      headers: { "Accept" => "application/json" }).and_return(vocabularies_response)
    end
  end

  describe "#error responses" do
    it "should abort if /api/services errored" do
      response = double(code: 500, body: {})
      expect_responses(unirest, test_url, response)
      expect { log_less_eosc_registry.call }.to raise_error(SystemExit).and output.to_stderr
    end
  end

  describe "#standard responses" do
    before(:each) do
      response = double(code: 200, body: create(:eosc_registry_vocabularies_response))
      expect_responses(unirest, test_url, response)
    end

    let!(:esfri_type) { create(:esfri_type, name: "TEST", eid: "provider_esfri_type-landmark") }

    it "should create and update vocabularies" do
      eosc_registry = make_and_stub_eosc_registry(log: true)

      expect { eosc_registry.call }.to output(/TOTAL: 26, CREATED: 21, UPDATED: 1, UNPROCESSED: 4$/).to_stdout.
        and change { Vocabulary.count }.by(15).
        and change { Category.count }.by(3).
        and change { ScientificDomain.count }.by(2).
        and change { TargetUser.count }.by(1)

      esfri_type.reload

      expect(esfri_type.name).to eq("Landmark")
    end

    it "should not change db if dry_run is set to true" do
      eosc_registry = make_and_stub_eosc_registry(dry_run: true, log: true)
      expect { eosc_registry.call }.to output(/TOTAL: 26, CREATED: 21, UPDATED: 1, UNPROCESSED: 4$/).to_stdout.
        and change { Vocabulary.count }.by(0).
        and change { Category.count }.by(0).
        and change { ScientificDomain.count }.by(0).
        and change { TargetUser.count }.by(0)
    end
  end
end
