# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each, type: :feature, js: true) do
    # Accept cookies. We need to visit any webpage and
    # set required cookie value. If cookies policy popup is shown
    # it leads to strange errors in JS tests saying that element cannot
    # be clicked because cookie policy popup is above the element.
    visit root_path
    page.driver.browser.manage.add_cookie(name: :cookieconsent_status, value: "dismiss")
  end
end
