# frozen_string_literal: true
class AddCountryPhoneCodeToContacts < ActiveRecord::Migration[7.2]
  def change
    add_column :contacts, :country_phone_code, :string
  end
end
