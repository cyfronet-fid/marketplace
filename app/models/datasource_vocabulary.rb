# frozen_string_literal: true

class DatasourceVocabulary < ApplicationRecord
  belongs_to :datasource
  belongs_to :vocabulary, polymorphic: true
  before_create :set_vocabulary_type

  validates :datasource, presence: true
  validates :vocabulary, presence: true

  def set_vocabulary_type
    self.vocabulary_type = vocabulary.type
  end
end
