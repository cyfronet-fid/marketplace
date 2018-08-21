# frozen_string_literal: true

class Order::Register
  class JIRAIssueCreateError < StandardError
    def initialize(order, msg = "")
      super(msg)
      @order = order
    end
  end

  def initialize(order)
    @order = order
  end

  def call
    register_in_jira! &&
    update_status! &&
    notify!
  end

  private

    def register_in_jira!
      client = Jira::Client.new
      issue = client.Issue.build
      if issue.save(fields: { summary: "Requested realization of #{@order.service.title}",
                              project: { key: client.jira_project_key },
                              issuetype: { id: client.jira_issue_type_id } })
        @order.update_attributes(issue_id: issue.id, issue_status: :jira_active)
        @order.save
        true
      else
        @order.jira_errored!
        raise JIRAIssueCreateError.new(@order)
      end
    end

    def update_status!
      @order.new_change(status: :registered,
                        message: "Your order was registered in the order handling system")
      true
    end

    def notify!
      OrderMailer.changed(@order).deliver_later
    end
end
