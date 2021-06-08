# frozen_string_literal: true

module WebsiteHelper
  def stub_website_check(source)
    stub_request(:get, source.website).
      with(headers: {
        "Accept": "*/*",
        "User-Agent": "unirest-ruby/1.0",
        "Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Host": source.website.gsub(/http(s?):\/\//, "")
      }).
      to_return(status: 200, body: "", headers: {})
  end
end
