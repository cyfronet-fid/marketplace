# frozen_string_literal: true

class Report::Client < Savon::Client
  include Rails.application.routes.url_helpers

  class XGUSIssueCreateError < StandardError
  end

  def initialize
    xgus_config = Mp::Application.config_for(:xgus)

    options = { wsdl: xgus_config["wsdl"],
                env_namespace: :soapenv,
                namespace_identifier: :urn,
                soap_header: { "urn:AuthenticationInfo" =>
                                   { "urn:userName" => xgus_config["username"],
                                     "urn:password" => xgus_config["password"] } } }
    super(options)
  end

  def create_xgus_issue(report)
    self.call(:op_create,
              message: { "XGS_Subject" => "EOSC-MP issue report",
                         "XGS_Description" => report.text,
                         "XGS_Name" => report.author,
                         "XGS_Email" => report.email })
  end
end
