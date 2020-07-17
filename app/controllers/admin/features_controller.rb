# frozen_string_literal: true

class Admin::FeaturesController < Admin::ApplicationController
  def enable_modal
    User.find_each { |u| u.update!(show_welcome_popup: true) }
    redirect_to admin_features_path,
                notice: "Welcome modal enabled for all first logged-in users"
  end

  def disable_modal
    User.find_each { |u| u.update!(show_welcome_popup: false) }
    redirect_to admin_features_path,
                notice: "Welcome modal disabled for all users"
  end
end
