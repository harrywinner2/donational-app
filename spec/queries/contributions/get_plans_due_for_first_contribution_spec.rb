require 'rails_helper'

RSpec.describe Contributions::GetPlansDueForFirstContribution do
  include ActiveSupport::Testing::TimeHelpers

  subject { Contributions::GetPlansDueForFirstContribution.call }

  context 'when the plans all have at least one contribution' do
    before do
      create(:subscription, start_at: 1.week.ago, last_scheduled_at: 1.week.ago)
      create(:subscription, start_at: Time.zone.now, last_scheduled_at: Time.zone.now)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there are unprocessed plans with future start dates' do
    before do
      create(:subscription, start_at: 1.week.from_now, last_scheduled_at: nil)
      create(:subscription, start_at: 1.month.from_now, last_scheduled_at: nil)
    end

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there are deactivated unprocessed plans with past start dates' do
    let!(:deactivated_past_due_plan) {
      create(:subscription, start_at: 1.day.ago, last_scheduled_at: nil, deactivated_at: 1.day.ago + 1.second)
    }

    it 'returns an empty relation' do
      expect(subject).to be_empty
    end
  end

  context 'when there are active unprocessed plans with past start dates' do
    around do |spec|
      travel_to(Date.new(Date.today.year,Date.today.month,20)) do
        spec.run
      end
    end
    let!(:recently_created_plan) { create(:subscription, start_at: Time.zone.now, last_scheduled_at: nil) }
    let!(:older_plan_that_still_has_no_contributons_scheduled) {
      create(:subscription, start_at: 1.week.ago, last_scheduled_at: nil)
    }
    let!(:future_plan) { create(:subscription, start_at: 1.month.from_now, last_scheduled_at: nil) }
    let!(:older_plan_that_has_contributions) { create(:subscription, start_at: 1.day.ago, last_scheduled_at: 1.day.ago) }

    it 'returns the unprocessed plans with past start dates' do
      expect(subject.size).to eq 2
      expect(subject).to include(recently_created_plan)
      expect(subject).to include(older_plan_that_still_has_no_contributons_scheduled)
    end
  end
end
