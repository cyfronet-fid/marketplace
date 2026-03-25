# frozen_string_literal: true

class Guideline::PcCreateOrUpdate < ApplicationService
  def initialize(guideline_data, status, modified_at)
    super()
    @guideline_data = guideline_data
    @status = status
    @modified_at = modified_at
    @is_active = status == :published
    @guideline = Guideline.find_by(eid: guideline_data["id"])
  end

  def call
    if @guideline.nil?
      create_guideline if @is_active
    else
      update_guideline
    end
  end

  private

  def create_guideline
    Guideline.create!(eid: @guideline_data["id"], title: @guideline_data["title"])
  end

  def update_guideline
    @guideline.update!(title: @guideline_data["title"])
    @guideline
  end
end
