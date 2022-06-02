# frozen_string_literal: true

class Vocabulary::PcCreateOrUpdate
  include Importable

  class ConnectionError < StandardError
  end

  class NotUpdatedError < StandardError
  end

  def initialize(vocabulary)
    @type = vocabulary["vocabulary"]["type"].parameterize(separator: "_").upcase
    @vocabulary_hash = Importers::Vocabulary.new(vocabulary["vocabulary"], @type).call
    @mp_vocabulary = clazz(@type).find_by(eid: @vocabulary_hash["id"])
  end

  def call
    create_new = @mp_vocabulary.nil?
    return create_vocabulary if create_new
    @mp_vocabulary.update!(@vocabulary_hash)
  end

  def create_vocabulary
    clazz(@type).create!(@vocabulary_hash)
  end
end
