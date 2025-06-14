module Contributions
  class GetSubscriptionsWhichNeedReminder < ApplicationQuery
    def initialize(relation = Subscription.all)
      @relation = relation
    end

    def call
      today = Date.today.beginning_of_day
      next_week = today + 7.days
      @relation
        .where(deactivated_at: nil)
        .where(last_reminded_at: nil)
        .where(start_at: today..next_week)
    end
  end
end
