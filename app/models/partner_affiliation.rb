# == Schema Information
#
# Table name: partner_affiliations
#
#  id                :uuid             not null, primary key
#  donor_id          :uuid
#  partner_id        :uuid
#  campaign_id       :uuid
#  custom_donor_info :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class PartnerAffiliation < ApplicationRecord
  belongs_to :partner
  belongs_to :donor
  belongs_to :campaign, optional: true
  belongs_to :referred_by_donor, optional: true, class_name: 'Donor'

  delegate :title, to: :campaign, prefix: true, allow_nil: true
  delegate :name, to: :partner, prefix: true

  after_commit :reindex_donor

  def donor_responses
    partner.donor_questions.map do |q|
      DonorResponse.new(question: q, value: custom_donor_info[q.name])
    end
  end

  def reindex_donor
    donor.reindex
  end

  class DonorResponse
    include ActiveModel::Model

    attr_reader :question, :value

    def initialize(question: nil, value: nil)
      @question = question
      @value = value
    end
  end
end
