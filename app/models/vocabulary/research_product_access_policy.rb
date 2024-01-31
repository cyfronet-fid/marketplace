# frozen_string_literal: true

class Vocabulary::ResearchProductAccessPolicy < Vocabulary
  after_save do
    Vocabulary::ResearchProductMetadataAccessPolicy.find_or_initialize_by(eid: eid).update(
      name: name,
      description: description
    )
  end
end
