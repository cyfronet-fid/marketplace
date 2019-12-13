# frozen_string_literal: true

class Executive::StatisticsController < Executive::ApplicationController
  def index
    report = UsageReport.new

    @orderable_count = report.orderable_count
    @not_orderable_count = report.not_orderable_count
    @all_services_count = report.all_services_count

    @providers = report.providers
    @providers_count = @providers.size

    @disciplines = report.disciplines
    @disciplines_count = @disciplines.size

    @countries = report.countries
    @countries_count = @countries.size
  end
end
