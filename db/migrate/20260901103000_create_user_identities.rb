# frozen_string_literal: true

# Ported from pl-marketplace with its original version, so pl databases that
# already ran it skip it. pl's migration also dropped users.uid; here the
# column stays because marketplace and whitelabel still log in through it
# (User::Checkin). AddNullableUidToUsers re-adds it on pl.
class CreateUserIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :user_identities do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.boolean :email_verified, null: false, default: false
      t.boolean :primary, null: false, default: false

      t.timestamps
    end

    add_index :user_identities, %i[provider uid], unique: true

    add_index(
      :user_identities,
      :user_id,
      unique: true,
      where: "primary",
      name: "index_user_identities_on_user_id_primary"
    )
  end
end
