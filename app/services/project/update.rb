# frozen_string_literal: true

class Project::Update
  def initialize(project, params)
    @project = project
    @params = params
  end

  def call
    Project::JiraUpdateJob.perform_later(@project) if @project.update(@params)
  end
end
