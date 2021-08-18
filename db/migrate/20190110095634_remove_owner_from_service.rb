# frozen_string_literal: true

class RemoveOwnerFromService < ActiveRecord::Migration[5.2]
  def change
    remove_reference :services, :owner
  end
end
