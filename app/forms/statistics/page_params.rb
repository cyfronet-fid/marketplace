# frozen_string_literal: true

module Statistics
  # The query of a Statistics API list request: from_id=0&limit=100&pid[]=….
  # The validations check the values as the client sent them, so "5abc" or
  # limit[]=1 is refused, not read as 5 or 0.
  class PageParams
    include ActiveModel::Model
    include ActiveModel::Attributes

    DEFAULT_LIMIT = 100
    MAX_LIMIT = 1000
    MAX_PIDS = 100

    # Before the attributes, so that each of them gets the method.
    attribute_method_suffix "_before_type_cast", parameters: false

    attribute :from_id, :integer, default: 0
    attribute :limit, :integer, default: DEFAULT_LIMIT
    attribute :pids

    validates :from_id,
              numericality: {
                only_integer: true,
                greater_than_or_equal_to: 0,
                message: "'from_id' must be a non-negative integer"
              }
    validates :limit,
              numericality: {
                only_integer: true,
                in: 1..MAX_LIMIT,
                message: "'limit' must be an integer from 1 to #{MAX_LIMIT}"
              }
    validate :pids_listed
    validates :pids,
              length: {
                maximum: MAX_PIDS,
                message: "'pid' must hold at most %{count} PIDs"
              },
              if: :pids_listed?

    # A blank from_id or limit takes its default; pid[] fills pids.
    def self.from_query(params)
      new({ from_id: params[:from_id].presence, limit: params[:limit].presence, pids: params[:pid] }.compact)
    end

    private

    # The value as the client sent it, which the numericality validator reads
    # when the model has it. ActiveRecord has it; ActiveModel::Attributes of
    # Rails 7.2 doesn't.
    def attribute_before_type_cast(name)
      @attributes[name].value_before_type_cast
    end

    def pids_listed?
      pids.is_a?(Array) && pids.all?(String)
    end

    def pids_listed
      errors.add(:pids, "'pid' must be a list of PIDs: pid[]=…&pid[]=…") unless pids.nil? || pids_listed?
    end
  end
end
