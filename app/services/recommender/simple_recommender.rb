#  frozen_string_literal: true

class Recommender::SimpleRecommender
  def call(n)
    recommended_services = get_recommended_services n
    fill_missing recommended_services, n
  end

  private

  def get_records(n)
    ActiveRecord::Base.connection.execute(sql_query % { n: n }).to_a
  end

  def get_recommended_services(n)
    records2services get_records(n)
  end

  def sql_query
    "" \
      "
      select Services.id from Services
      -- Join projects
      join Offers on Offers.service_id=Services.id
      join Project_items on Project_items.offer_id=Offers.id
      join Projects on Projects.id=Project_items.project_id
      -- Join categories
      join Categorizations on Categorizations.service_id=Services.id
      join Categories on Categories.id=Categorizations.category_id
      where Categories.id=(select Categories.id from Services
                          -- Join projects
                          join Offers on Offers.service_id=Services.id
                          join Project_items on Project_items.offer_id=Offers.id
                          join Projects on Projects.id=Project_items.project_id
                          -- Join categories
                          join Categorizations on Categorizations.service_id=Services.id
                          join Categories on Categories.id=Categorizations.category_id
                          group by Categories.id
                          order by count(Services.name) desc
                          limit 1)
      group by Services.id
      order by count(Services.name) desc
      limit %{n}
      " \
      ""
  end

  def records2services(records_array)
    records_array.map { |h| Service.find h["id"] }
  end

  def fill_missing(recommended_services, n)
    if recommended_services.length < n
      additional_services = Service.all[0..(n - recommended_services.length - 1)]
      recommended_services = recommended_services + additional_services
    end
    recommended_services
  end
end
