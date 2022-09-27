# frozen_string_literal: true

class Vocabulary::ResearchProductAccessPolicy < Vocabulary
  after_save do
    Vocabulary::ResearchProductMetadataAccessPolicy.new(name: name, eid: eid, description: description).save
  end
end
