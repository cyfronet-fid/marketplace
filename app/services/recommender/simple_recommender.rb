#  frozen_string_literal: true

class Recommender::SimpleRecommender
  def call(size)
    recommended_services = get_recommended_services size
    fill_missing recommended_services, size
  end

  private

  def get_records(size)
    ActiveRecord::Base.connection.execute(format(sql_query, n: size)).to_a
  end

  def get_recommended_services(size)
    records2services get_records(size)
  end

  def sql_query
    "" \
      "
      select Services.id from Services
      -- Join projects (using polymorphic orderable)
      join Offers on Offers.orderable_id=Services.id AND Offers.orderable_type='Service'
      join Project_items on Project_items.offer_id=Offers.id
      join Projects on Projects.id=Project_items.project_id
      -- Join categories
      join Categorizations on Categorizations.service_id=Services.id
      join Categories on Categories.id=Categorizations.category_id
      where Categories.id=(select Categories.id from Services
                          -- Join projects (using polymorphic orderable)
                          join Offers on Offers.orderable_id=Services.id AND Offers.orderable_type='Service'
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

  def fill_missing(recommended_services, expected_size)
    if recommended_services.length < expected_size
      additional_services = Service.all[0..(expected_size - recommended_services.length - 1)]
      recommended_services += additional_services
    end
    recommended_services
  end
end
