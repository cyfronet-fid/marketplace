# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateHelper, type: :helper, backend: true do
  it "converts date from proper date formatted string" do
    date = "2001-02-03T04:05:06Z"
    date_utc = "2001-02-03T04:05:06.000000Z"
    expect(from_timestamp(date)).to eq(date_utc)
  end

  it "converts date from proper date formatted string with milisec" do
    date = "2001-02-03T04:05:06.123456Z"
    date_utc = "2001-02-03T04:05:06.123456Z"
    expect(from_timestamp(date)).to eq(date_utc)
  end

  it "converts date from proper date UTC" do
    date = "2017-09-27T16:46:41Z"
    date_utc = "2017-09-27T16:46:41.000000+00:00"
    expect(from_timestamp(date)).to eq(date_utc)
  end

  it "converts date from proper date UTC with milisec" do
    date = "2017-09-27T16:46:41.003456Z"
    date_utc = "2017-09-27T16:46:41.003456+00:00"
    expect(from_timestamp(date)).to eq(date_utc)
  end

  it "converts date from proper date UTC with some milisec" do
    date = "2017-09-27T16:46:41.1234Z"
    date_utc = "2017-09-27T16:46:41.123400+00:00"
    expect(from_timestamp(date)).to eq(date_utc)
  end

  it "raise error when string integer as date" do
    expect { from_timestamp("100") }.to raise_error(ArgumentError)
  end

  it "raise error when negative string integer as date" do
    expect { from_timestamp("-100") }.to raise_error(ArgumentError)
  end

  it "raise error when string as date" do
    expect { from_timestamp("asd") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong format" do
    expect { from_timestamp("2022-02-10T08:13:06") }.to raise_error(ArgumentError)
  end

  it "raise error when string date with minus" do
    expect { from_timestamp("-2001-02-03T04:05:06+07:00") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong format - wrong zone" do
    expect { from_timestamp("2022-02-10T04:05:06+022:00") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong format - wrong zone2" do
    expect { from_timestamp("2022-02-10T04:05:06+07:00jjj") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong format - wrong zone3" do
    expect { from_timestamp("2022-02-10T04:05:06+77790:00") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong format - wrong zone4" do
    expect { from_timestamp("2022-02-10T04:05:06.123456Zyyy") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong date" do
    expect { from_timestamp("1235322022-02-10T04:05:06.123456Zyyy") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong format - wrong end" do
    expect { from_timestamp("2022-02-10T04:05:4yuuu") }.to raise_error(ArgumentError)
  end

  it "raise error when date of wrong date2" do
    expect { from_timestamp("2022-02-30T04:05:04Z") }.to raise_error(ArgumentError)
  end
end
