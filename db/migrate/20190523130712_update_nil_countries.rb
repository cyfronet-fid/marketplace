class UpdateNilCountries < ActiveRecord::Migration[5.2]
  def up
    execute("UPDATE projects set country_of_customer = 'N/A' where country_of_customer IS NULL;")
    execute("UPDATE projects set country_of_collaboration = '{N/A}' where country_of_collaboration IS NULL;")
  end
end
