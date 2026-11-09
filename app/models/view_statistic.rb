# frozen_string_literal: true

# The Views and visits of one Service, Provider or Bundle on one day, as read
# back from Matomo by Statistics::SyncViews (ADR-0008 D8, D9). Only views are
# exposed, through usage_counts_views; visits are stored for later use.
class ViewStatistic < ApplicationRecord
  belongs_to :viewable, polymorphic: true
end
