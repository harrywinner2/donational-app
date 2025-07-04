module Partners
  class GetPartnerForDonor < ApplicationQuery
    def initialize(relation = PartnerAffiliation.all)
      @relation = relation
    end

    def call(donor:)
      @relation.order(created_at: :desc).where(donor: donor).first.try(:partner) || default_partner
    end

    def default_partner
      Partner.find_by(name: Partner::DEFAULT_PARTNER_NAME)
    end
  end
end
