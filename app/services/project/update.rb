# frozen_string_literal: true

class Project::Update
  def initialize(project, params)
    @project = project
    @params = params
  end

  def call
    if @project.update(@params)
      Project::JiraUpdateJob.perform_later(@project)
    end
  end
end
