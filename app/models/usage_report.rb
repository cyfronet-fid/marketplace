# frozen_string_literal: true

class UsageReport
  def orderable_count
    service_count_by_order_type(:orderable)
  end

  def not_orderable_count
    service_count_by_order_type(:open_access, :external)
  end

  def all_services_count
    Service.where(status: [:published, :unverified]).count
  end

  def providers
    Provider.pluck(:name)
  end

  def disciplines
    ScientificDomain.joins(:projects)
      .where(projects: { id: used_projects.map { |p| p.id } }).uniq
      .pluck(:name)
  end

  def countries
    used_projects
      .reject { |p| p.country_of_origin.nil? }
      .map { |p| p.country_of_origin.name }
      .uniq
  end

  private
    def used_projects
      @used_projects ||= Project.joins(:project_items)
        .select("projects.id, projects.country_of_origin, count(project_items.id) as pi_count")
        .group("projects.id")
    end

    def service_count_by_order_type(*types)
      Service.joins(:offers)
        .where(offers: { order_type: types, status: :published },
               status: [:published, :unverified])
        .uniq.count
    end
end
