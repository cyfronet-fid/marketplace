# frozen_string_literal: true

class ProjectItemMailer < ApplicationMailer
  include ProjectItemsHelper

  def created(project_item)
    load_data(project_item)
    if @project_item.created?
      mail(
        to: @user.email,
        subject: "New request for the service access in the EOSC Marketplace - CREATED",
        template_name: "created"
      )
    end
  end

  def added_to_project(project_item)
    load_data(project_item)

    mail(
      to: @user.email,
      subject: "The service #{@project_item.service.name} has been added to your project",
      template_name: "added_to_project"
    )
  end

  def waiting_for_response(project_item)
    load_data(project_item)

    mail(
      to: @user.email,
      subject:
        "Status of your service access request " \
          "in the EOSC Portal Marketplace has changed to WAITING FOR RESPONSE",
      template_name: "waiting_for_response"
    )
  end

  def approved(project_item)
    load_data(project_item)

    mail(
      to: @user.email,
      subject: "Status of your service access request in the EOSC Portal Marketplace has changed to APPROVED",
      template_name: "approved"
    )
  end

  def ready_to_use(project_item)
    load_data(project_item)

    mail(
      to: @user.email,
      subject: "Status of your service access request in the EOSC Portal Marketplace has changed to READY TO USE",
      template_name: "ready_to_use"
    )
  end

  def rejected(project_item)
    load_data(project_item)

    mail(
      to: @user.email,
      subject: "Status of your service access request in the EOSC Portal Marketplace has changed to REJECTED",
      template_name: "rejected"
    )
  end

  def closed(project_item)
    load_data(project_item)

    mail(
      to: @user.email,
      subject: "Status of your service access request in the EOSC Portal Marketplace has changed to CLOSED",
      template_name: "closed"
    )
  end

  def rate_service(project_item)
    @project_item = project_item
    @project = project_item.project
    @user = project_item.user

    mail(to: @user.email, subject: "EOSC Portal - Rate your service", template_name: "rating_service")
  end

  def aod_voucher_accepted(project_item)
    @user = project_item.user
    @voucher_id = voucher_id(project_item)

    mail(
      to: @user.email,
      subject: "Elastic Cloud Compute Cluster (EC3) service with voucher approved",
      template_name: "aod_voucher_accepted"
    )
  end

  def aod_voucher_rejected(project_item)
    @user = project_item.user
    @voucher_id = voucher_id(project_item)

    mail(
      to: @user.email,
      subject: "Elastic Cloud Compute Cluster (EC3) service with voucher rejected",
      template_name: "aod_voucher_rejected"
    )
  end

  def aod_accepted(project_item)
    @user = project_item.user

    mail(to: @user.email, subject: "EGI Applications on Demand service approved", template_name: "aod_accepted")
  end

  def activate_message(project_item, service)
    @user = project_item.user
    @activate_message = service.activate_message

    mail(
      to: @user.email,
      subject: "[EOSC marketplace] #{service.name} is ready - usage instructions",
      template_name: "activate_message"
    )
  end

  private

  def load_data(project_item)
    @project_item = project_item
    @project = project_item.project
    @user = project_item.user
  end
end
