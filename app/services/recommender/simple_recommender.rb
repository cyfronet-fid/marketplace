#  frozen_string_literal: true

class Recommender::SimpleRecommender
  def call(quantity)
    recommended_services = get_recommended_services quantity
    fill_missing recommended_services, quantity
  end

  private

  def get_records(quantity)
    ActiveRecord::Base.connection.execute(format(sql_query, n: quantity)).to_a
  end

  def get_recommended_services(quantity)
    records2services get_records(quantity)
  end

  def sql_query
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
      limit %<n>s
      "
  end

  def records2services(records_array)
    records_array.map { |h| Service.find h["id"] }
  end

  def fill_missing(recommended_services, quantity)
    if recommended_services.length < quantity
      additional_services = Service.all[0..(quantity - recommended_services.length - 1)]
      recommended_services += additional_services
    end
    recommended_services
  end
end
