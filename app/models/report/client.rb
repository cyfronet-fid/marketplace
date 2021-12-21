# frozen_string_literal: true

class Report::Client
  include Rails.application.routes.url_helpers

  class XGUSIssueCreateError < StandardError
  end

  def initialize
    xgus_config = Mp::Application.config_for(:xgus)

    options = {
      wsdl: xgus_config["wsdl"],
      env_namespace: :soapenv,
      namespace_identifier: :urn,
      soap_header: {
        "urn:AuthenticationInfo" => {
          "urn:userName" => xgus_config["username"],
          "urn:password" => xgus_config["password"]
        }
      }
    }
    @client = Savon::Client.new(options)
  end

  def create!(report)
    @client.call(
      :op_create,
      message: {
        "XGS_Subject" => "EOSC-MP issue report",
        "XGS_Description" => report.text,
        "XGS_Name" => report.author,
        "XGS_Email" => report.email
      }
    )
  rescue Error => e
    raise XGUSIssueCreateError => e.message
  end
end
