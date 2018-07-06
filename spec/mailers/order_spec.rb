# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderMailer, type: :mailer do
  context "order created" do
    let(:order) { build(:order, id: 1) }
    let(:mail) { described_class.created(order).deliver_now }

    it "sends email to order owner" do
      expect { mail }.to change { ActionMailer::Base.deliveries.count }.by(1)
      expect(mail.to).to contain_exactly(order.user.email)
    end

    it "email contains order details" do
      encoded_body = mail.body.encoded

      expect(encoded_body).to match(/#{order.user.full_name}/)
      expect(encoded_body).to match(/#{order.service.title}/)
      expect(encoded_body).to match(/#{order_url(order)}/)
    end
  end

  context "order change" do
    it "notifies about order status change" do
      order = create(:order)
      order.new_change(status: :created, message: "Order created")
      order.new_change(status: :registered, message: "Order registered")

      mail = described_class.changed(order).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/status changed/)
      expect(encoded_body).to match(/from "created" to "registered"/)
      expect(encoded_body).to match(/#{order_url(order)}/)
    end

    it "notifies about new order message" do
      order = create(:order)
      order.new_change(status: :created, message: "Order created")
      order.new_change(status: :created, message: "New message")

      mail = described_class.changed(order).deliver_now
      encoded_body = mail.body.encoded

      expect(mail.subject).to match(/new message/)
      expect(encoded_body).to match(/New message was added/)
      expect(encoded_body).to match(/#{order_url(order)}/)
    end
  end
end
