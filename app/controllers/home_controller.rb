# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :load_services, :load_platforms, :load_providers, :load_target_users, :load_opinion

  def index
    @learn_more_section = LeadSection.includes(:leads).find_by(slug: "learn-more")
    @use_cases_section = LeadSection.includes(:leads).find_by(slug: "use-cases")
    @root_categories_with_logos = @root_categories.with_attached_logo.reject { |c| c.name == "Other" }
    @main_scientific_domains =
      ScientificDomain.with_attached_logo.roots.partition { |sd| sd.name != "Other" }.flatten(1)
  end

  def robots
    robots = File.read(Rails.root + "config/robots.#{Rails.application.config.robots}.txt")
    render plain: robots, layout: false, content_type: "text/plain"
  end

  private

  def load_services
    @providers_number = Provider.count
    @services_number = Service.count
    @countries_number = 32
    @services = Service.popular(6)
  end

  def load_platforms
    @home_platforms = Platform.joins(:services).uniq.sample(10).map
    @home_platforms_counter = Platform.all.count - @home_platforms.count
  end

  def load_providers
    @home_providers = Provider.joins(:services).uniq.sample(5)
    @home_providers_counter = Provider.all.count - @home_providers.count
  end

  def load_target_users
    @home_target_users = TargetUser.all.first(5)
    @home_target_users_counter = TargetUser.all.count - @home_target_users.count
  end

  def load_opinion
    @opinion = ServiceOpinion.joins(project_item: { offer: :service })
                             .where(project_item: { offer: { services: { status: %i[published
                                                                                    unverified
                                                                                    errored] } } }).sample
  end
end
