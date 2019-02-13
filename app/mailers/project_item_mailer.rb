# frozen_string_literal: true

class ProjectItemMailer < ApplicationMailer
  def created(project_item)
    @project_item = project_item
    @user = project_item.user

    mail(to: @user.email,
         subject: "New request for service access in EOSC Portal Marketplace created")
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

    mail(to: @user.email,
         subject: "EOSC Portal - Rate your service", template_name: "rating_service")
  end

  def aod_voucher_accepted(project_item)
    @user = project_item.user
    @voucher_id = project_item.voucher_id

    mail(to: @user.email,
       subject: "EGI Applications on Demand service with voucher approved",
       template_name: "aod_voucher_accepted")
  end

  def aod_accepted(project_item)
    @user = project_item.user

    mail(to: @user.email,
         subject: "EGI Applications on Demand service approved",
         template_name: "aod_accepted")
  end

  private
    def new_message(project_item)
      @user = project_item.user

      mail(to: @user.email,
           subject: "Question about your service access request in EOSC Portal Marketplace",
           template_name: "new_message")
    end

    def status_changed(project_item)
      @user = project_item.user

      mail(to: @user.email,
            subject: "Status of your service access request in EOSC Portal Marketplace has changed",
            template_name: "changed")
    end
end
