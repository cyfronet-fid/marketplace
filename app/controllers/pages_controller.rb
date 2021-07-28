# frozen_string_literal: true

class PagesController < ApplicationController
  def about
  end

  def about_projects
  end

  def communities
    @platforms = Platform.all.order(:name)
  end

  def target_users
    @target_users = TargetUser.all.order(:name).partition { |tu|  tu.name != "Other" }.flatten(1)
  end
end
