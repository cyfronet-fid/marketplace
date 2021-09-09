# frozen_string_literal: true

module CookieHelper
  def cookie(name)
    Capybara.current_session.driver.browser.manage.cookie_named(name)
  end

  def set_cookie(name, value)
    Capybara.current_session.driver.browser.manage.add_cookie({ name: name, value: value })
  end
end
