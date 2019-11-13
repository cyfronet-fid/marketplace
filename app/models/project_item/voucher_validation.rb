# frozen_string_literal: true

module ProjectItem::VoucherValidation
  extend ActiveSupport::Concern

  included do
    validates :request_voucher, absence: true, unless: :voucherable?
    validates :voucher_id, absence: true, if: :voucher_id_unwanted?
    validates :voucher_id, presence: true, allow_blank: false, if: :voucher_id_required?
  end

  def voucherable?
    offer&.voucherable
  end

  def voucher_id_required?
    voucherable? && request_voucher == false
  end

  def voucher_id_unwanted?
    created? && !voucher_id_required?
  end
end
