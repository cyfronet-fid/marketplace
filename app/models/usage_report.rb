# frozen_string_literal: true

class UsageReport
  def orderable_count
    service_count_by_order_type(:order_required, internal: true)
  end

  def not_orderable_count
    all_services_count - orderable_count
  end

  def order_required_count
    service_count_by_order_type(:order_required)
  end

  def open_access_count
    service_count_by_order_type(:open_access)
  end

  def fully_open_access_count
    service_count_by_order_type(:fully_open_access)
  end

  def other_count
    service_count_by_order_type(:other)
  end

  def all_services_count
    Service.where(status: %i[published errored]).count
  end

  def providers
    Provider.active.pluck(:name)
  end

  def domains
    ScientificDomain.joins(:projects).where(projects: { id: used_projects.map(&:id) }).uniq.pluck(:name)
  end

  def countries
    used_projects.reject { |p| p.country_of_origin.nil? }.map { |p| p.country_of_origin.iso_short_name }.uniq
  end

  private

  def used_projects
    @used_projects ||=
      Project
        .joins(:project_items)
        .select("projects.id, projects.country_of_origin, count(project_items.id) as pi_count")
        .group("projects.id")
  end

  def service_count_by_order_type(*types, internal: false)
    statuses = %w[published errored]
    if internal
      Service
        .joins(:offers)
        .where(
          "offers.order_type IN (?) AND services.status IN (?) AND " + "offers.status IN (?) AND offers.internal = ?",
          types.to_a,
          statuses,
          "published",
          true
        )
        .uniq
        .count
    else
      Service
        .left_outer_joins(:offers)
        .where(
          "(services.order_type IN (?) OR (offers.order_type IN (?) AND " \
            "offers.status = ?)) AND services.status IN (?)",
          types.to_a,
          types.to_a,
          "published",
          statuses
        )
        .uniq
        .count
    end
  end
end
