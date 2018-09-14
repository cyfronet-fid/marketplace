# frozen_string_literal: true

class Order::Ready
  class JIRAIssueCreateError < StandardError
    def initialize(order, msg = "")
      super(msg)
      @order = order
    end
  end

  class JIRATransitionSaveError < StandardError
    def initialize(order, msg = "")
      super(msg)
      @order = order
    end
  end

  def initialize(order)
    @order = order
  end


  def call
    ready_in_jira! &&
    update_status! &&
    notify!
  end

  private
    def ready_in_jira!
      client = Jira::Client.new
      issue = client.Issue.build

      if issue.save(fields: { summary: "Add open service #{@order.service.title}",
                          project: { key: client.jira_project_key },
                          issuetype: { id: client.jira_issue_type_id } })
        trs = issue.transitions.all.select { |tr| tr.name == "Done" }
        if trs.length > 0
          transition = issue.transitions.build
          transition.save!("transition" => { "id" => trs.first.id })
          @order.update_attributes(issue_id: issue.id, issue_status: :jira_active)
        else
          raise JIRATransitionSaveError.new(@order)
        end

      else
        @order.jira_errored!
        raise JIRAIssueCreateError.new(@order)
      end
    end

    def update_status!
      @order.new_change(status: :ready,
                        message: "Your order is ready")
    end

    def notify!
      OrderMailer.changed(@order).deliver_later
      OrderMailer.rate_service(@order).deliver_later(wait_until: RATE_AFTER_PERIOD.from_now)
    end
end
