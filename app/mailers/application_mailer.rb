# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  # pl's sender; marketplace and whitelabel keep their placeholder.
  default from: -> { ENV.fetch("FROM_EMAIL") { Mp::Variant.pl? ? "EOSC PL <eosc-noreply@eosc.pl>" : "from@example.com" } }
  layout "mailer"

  helper MailerHelper
  helper_method :logo_name

  before_action :attach_logo, if: -> { logo_path.present? }

  private

  def attach_logo
    attachments.inline[logo_name] = File.binread(logo_path)
  end

  def logo_name
    logo_path.present? ? "header_#{File.basename(logo_path)}" : nil
  end

  def logo_path
    Rails.configuration.mail_logo_path
  end
end
