# frozen_string_literal: true

class Affiliation::Create
  def initialize(affiliation)
    @affiliation = affiliation
  end

  def call
    if @affiliation.save
      AffiliationMailer.verification(@affiliation).deliver_later
    end

    @affiliation
  end
end
