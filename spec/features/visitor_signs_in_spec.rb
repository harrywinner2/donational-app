require 'rails_helper'

RSpec.describe 'Visitor signs in', type: :feature do
  context 'when there is a donor with matching email' do
    before { create(:donor, first_name: 'Donny', last_name: 'Donator', email: 'user@example.com') }

    scenario 'with valid credentials', js: true do
      create(:partner, :default)
      visit root_path
      sign_in_as!(email: 'UsEr@exAmplE.com')
      visit root_path
    end
  end

  def sign_in_as!(email:)
    OmniAuth.config.add_mock(
      :auth0,
      {
        uid: '12345', info: { email: email }
      }
    )

    visit auth_oauth2_callback_path
  end
end
