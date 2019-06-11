# frozen_string_literal: true

class Project::Create
  def initialize(project)
    @project = project
  end

  def call
    @project.save!
    Project::ProjectRegisterJob.perform_later(@project)

    @project
  end
end
