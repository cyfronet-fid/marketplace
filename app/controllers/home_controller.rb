# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :load_services, :load_platforms, :load_providers, :load_target_groups, :load_opinion

  def index
    @root_categories = @root_categories.with_attached_logo
  end

  private
    def load_services
      @providers_number = Provider.count
      @services_number = Service.count
      @countries_number = 32
      @services = Service.published.includes(:providers).order(rating: :asc, title: :desc).limit(8)
    end

    def load_platforms
      @home_platforms = Platform.joins(:services).uniq.sample(10).map
      @home_platforms_counter = Platform.all.count - @home_platforms.count
    end

    def load_providers
      @home_providers = Provider.joins(:services).uniq.sample(5)
      @home_providers_counter = Provider.all.count - @home_providers.count
    end

    def load_target_groups
      @home_target_groups = TargetGroup.all.first(5)
      @home_target_groups_counter = TargetGroup.all.count - @home_target_groups.count
    end

    def load_opinion
      @opinion = ServiceOpinion.all.sample
    end
end
