# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_secure_token

  enum status: {
    created: "created",
    active: "active"
  }

  belongs_to :user

  has_many :project_items, dependent: :restrict_with_error

  validate :set_iid, on: :create
  validates :iid, presence: true, numericality: true
  validates :organization, presence: true
  validates :email, presence: true, "valid_email_2/email": true
  validates :webpage, presence: true
  validate :email_from_webpage_domain, if: :email

  validates :status, presence: true
  validates :token, uniqueness: true

  def self.find_by_token(token)
    token = nil if token&.strip.blank?

    where.not(token: nil).find_by(token: token)
  end

  def to_param
    iid.to_s
  end

  private

    def set_iid
      self.iid = user.affiliations.maximum(:iid).to_i + 1 if iid.blank?
    end

    def email_from_webpage_domain
      unless email_in_webpage_domain?
        errors.add(:email, "Email does not belong to webpage domain")
      end
    end

    def email_in_webpage_domain?
      /((\A|.+\.)|(https?:\/\/|https?:\/\/.+\.))#{email_domain_regexp}\z/.
        match?(webpage)
    end

    def email_domain_regexp
      email.downcase.split("@").last.sub(".", "\.") unless email.blank?
    end
end
