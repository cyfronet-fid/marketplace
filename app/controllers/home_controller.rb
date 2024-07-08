# frozen_string_literal: true

class HomeController < ApplicationController
  include LandingPageHelper
  before_action :load_services, :load_platforms, :load_providers, :load_target_users, :load_opinion

  layout "clear"

  def index
    @learn_more_section = LeadSection.includes(:leads).find_by(slug: "learn-more")
    @use_cases_section = LeadSection.includes(:leads).find_by(slug: "use-cases")

    # this hack with the research_step is temporary and should be integrated into CMS backend
    # @root_categories_with_logos = @root_categories.with_attached_logo.reject { |c| c.name == "Other" }
    # rubocop:disable Layout/LineLength
    @root_categories_with_logos = [
      {
        name: "Discover Research Outputs",
        logo: "research_step/ico-01.png",
        url: "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Discover%20Research%20Outputs%22)"
      },
      {
        name: "Publish Research Outputs",
        logo: "research_step/ico-02.png",
        url: "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Publish%20Research%20Outputs%22)"
      },
      {
        name: "Access Computing and Storage Services",
        logo: "research_step/ico-03.png",
        url:
          "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Access%20Computing%20and%20Storage%20Resources%22)"
      },
      {
        name: "Process and Analyse",
        logo: "research_step/ico-04.png",
        url: "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Process%20and%20Analyse%22)"
      },
      {
        name: "Access Research Infrastructures",
        logo: "research_step/ico-05.png",
        url:
          "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Access%20Research%20Infrastructures%22)"
      },
      {
        name: "Manage Research Data",
        logo: "research_step/ico-06.png",
        url: "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Manage%20Research%20Data%22)"
      },
      {
        name: "Access Training Material",
        logo: "research_step/ico-07.png",
        url: "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Access%20Training%20Material%22)"
      },
      {
        name: "Find Instruments & Equipment",
        logo: "research_step/ico-09.png",
        url:
          "#{external_search_base_url}/search/all?q=*&fq=unified_categories:(%22Find%20Instruments%20%5C%26%20Equipment%22)"
      }
    ]

    # rubocop:enable Layout/LineLength

    @main_scientific_domains =
      ScientificDomain.with_attached_logo.roots.partition { |sd| sd.name != "Other" }.flatten(1)
    @action = "landing_page"
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
    @services = Service.popular(4)
  end

  def load_platforms
    @home_platforms = Platform.all.uniq.sample(10).map
    @home_platforms_counter = Platform.all.count - @home_platforms.count
  end

  def load_providers
    @home_providers = Provider.active.joins(:services).uniq.sample(5)
    @home_providers_counter = Provider.active.count - @home_providers.count
  end

  def load_target_users
    @home_target_users = TargetUser.all.first(5)
    @home_target_users_counter = TargetUser.all.count - @home_target_users.count
  end

  def load_opinion
    @opinion =
      ServiceOpinion
        .joins(project_item: { offer: :service })
        .where(project_item: { offer: { services: { status: %i[published errored] } } })
        .sample
  end
end
