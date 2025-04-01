# frozen_string_literal: true

class PagesController < ApplicationController
  helper_method :community_link
  helper_method :target_users_link
  def about
  end

  def about_projects
  end

  def community_link(platform)
    return @search_base_url + "/search/service?q=*&fq=platforms:(%22#{platform.name}%22)" if @enable_external_search
    services_path(related_platforms: platform.to_param)
  end

  def target_users_link(target_user)
    target_link = @search_base_url + "/search/service?q=*&fq=dedicated_for:(%22#{target_user.name}%22)"
    return target_link if @enable_external_search
    services_path(dedicated_for: target_user.to_param)
  end

  def communities
    @platforms = Platform.all.order(:name)
  end

  def target_users
    return redirect_to @search_base_url + "/search/all?q=*" if @enable_external_search
    @target_users = TargetUser.all.order(:name).partition { |tu| tu.name != "Other" }.flatten(1)
  end

  def initialize
    super
    @search_base_url = Mp::Application.config.search_service_base_url
    @enable_external_search = Mp::Application.config.enable_external_search
  end

  def landing_page
    render layout: "clear"
  end
end
