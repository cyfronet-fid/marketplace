# frozen_string_literal: true

class ProjectItemMailer < ApplicationMailer
  def created(project_item)
    @project_item = project_item
    @user = project_item.user

    mail(to: @user.email, subject: "#{prefix(project_item)} created")
  end

  def changed(project_item)
    changes = project_item.project_item_changes.last(2)

    if changes.size > 1
      @project_item = project_item
      @user = project_item.user
      @current_status = changes.second.status
      @previous_status = changes.first.status

      if @current_status == @previous_status
        new_message(project_item)
      else
        status_changed(project_item)
      end
    end
  end

  def rate_service(project_item)
    @project_item = project_item
    @user = project_item.user

    mail(to: @user.email, subject: "EOSC Portal - Rate your service", template_name: "rating_service")
  end

  def new_message(project_item)
    mail(to: @user,
         subject: "#{prefix(project_item)} new message",
         template_name: "new_message")
  end

  private

    def status_changed(project_item)
      mail(to: @user,
            subject: "#{prefix(project_item)} status changed",
            template_name: "changed")
    end

    def prefix(project_item)
      "[ProjectItem ##{project_item.id}]"
    end
end
