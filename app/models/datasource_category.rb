# frozen_string_literal: true

class DatasourceCategory < ApplicationRecord
  belongs_to :datasource
  belongs_to :category

  validates :datasource, presence: true
  validates :category, presence: true

  after_save :guarantee_only_one_main, if: :main?

  private

  def guarantee_only_one_main
    DatasourceCategory.where(datasource: datasource).where.not(id: id).update(main: false)
  end
end
