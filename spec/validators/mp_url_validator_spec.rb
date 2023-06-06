# frozen_string_literal: true

require "rails_helper"

module Test
  MpUrlValidatable =
    Struct.new(:webpage) do
      include ActiveModel::Validations

      validates :webpage, mp_url: true
    end
end

# Validator tests with the test object
describe MpUrlValidator, type: :model, backend: true do
  subject { Test::MpUrlValidatable.new("http://testvalid.com") }

  it { is_expected.to be_valid(:webpage) }

  it "require webpage to be valid mp_url" do
    subject.webpage = "http://www.abc def.com"
    expect(subject.valid?).to be_falsey
    subject.webpage = "https://www.aaaaa.com/search?arg=\"Ala ma kota\""
    expect(subject.valid?).to be_truthy
    subject.webpage = "https://www.google.com/a/b/ala ma/search"
    expect(subject.valid?).to be_falsey
  end

  it "require http/https" do
    subject.webpage = "www.abcdef.com"
    expect(subject.valid?).to be_falsey
    subject.webpage = "http://www.abcdef.com"
    expect(subject.valid?).to be_truthy
    subject.webpage = "http://www.abcdef.com"
    expect(subject.valid?).to be_truthy
  end

  it "required suffix" do
    subject.webpage = "http://bcdef"
    expect(subject.valid?).to be_falsey
  end

  it "forbidden local" do
    subject.webpage = "http://localhost:5000/projects/1"
    expect(subject.valid?).to be_falsey
  end
end
