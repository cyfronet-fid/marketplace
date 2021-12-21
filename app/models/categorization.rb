# frozen_string_literal: true

class Categorization < ApplicationRecord
  belongs_to :service
  belongs_to :category

  validates :service, presence: true
  validates :category, presence: true

  after_save :guarantee_only_one_main, if: :main?

  private

  def guarantee_only_one_main
    Categorization.where(service: service).where.not(id: id).update(main: false)
  end
end
