# frozen_string_literal: true

# == Schema Information
#
# Table name: contributions
#
#  id                              :uuid             not null, primary key
#  portfolio_id                    :uuid
#  amount_cents                    :integer
#  receipt                         :json
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  scheduled_at                    :datetime
#  processed_at                    :datetime
#  tips_cents                      :integer          default(0)
#  donor_id                        :uuid
#  failed_at                       :datetime
#  payment_processor_fees_cents    :integer
#  refunded_at                     :datetime
#  external_reference_id           :string
#  partner_id                      :uuid
#  partner_contribution_percentage :integer          default(0)
#  amount_currency                 :string           default("usd"), not null
#  payment_processor_account_id    :string
#  platform_fees_cents             :integer
#  donor_advised_fund_fees_cents   :integer
#

# Funds withdrawn from a Donor and transferred to Donational
class Contribution < ApplicationRecord
  belongs_to :portfolio
  belongs_to :donor
  belongs_to :partner
  has_many :donations, dependent: :destroy
  has_many :organizations, through: :donations

  enum payment_status: {
    unprocessed: 'unprocessed',
    pending: 'pending',
    succeeded: 'succeeded',
    failed: 'failed',
    refunded: 'refunded',
    disputed: 'disputed'
  }

  validates :external_reference_id, uniqueness: { scope: :partner }, allow_nil: true
  validates :amount_currency, presence: true

  delegate :name, to: :donor, prefix: true
  delegate :email, to: :donor, prefix: true

  def amount_dollars
    amount_cents / 100.0
  end

  def total_charges_cents
    amount_cents + tips_cents
  end
end
