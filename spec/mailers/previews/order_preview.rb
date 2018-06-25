# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/order
#
# !!! We are using last created order to show email previews !!!
class OrderPreview < ActionMailer::Preview
  def created
    OrderMailer.created(Order.last)
  end

  def changed
    OrderMailer.changed(Order.last)
  end

  def new_message
    OrderMailer.new_message(Order.last)
  end
end
