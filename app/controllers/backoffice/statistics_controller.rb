# frozen_string_literal: true

class Backoffice::StatisticsController < Backoffice::ApplicationController
  def index
    report = UsageReport.new

    @orderable_count = report.orderable_count
    @not_orderable_count = report.not_orderable_count
    @all_services_count = report.all_services_count

    @order_required_count = report.order_required_count
    @open_access_count = report.open_access_count
    @fully_open_access_count = report.fully_open_access_count
    @other_count = report.other_count

    @providers = report.providers
    @providers_count = @providers.size

    @disciplines = report.domains
    @disciplines_count = @disciplines.size

    @countries = report.countries
    @countries_count = @countries.size
  end
end
