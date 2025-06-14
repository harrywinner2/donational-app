Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :auth0,
    ENV.fetch('AUTH0_CLIENT_ID'),
    ENV.fetch('AUTH0_CLIENT_SECRET'),
    ENV.fetch('AUTH0_DOMAIN'),
    callback_path: '/auth/oauth2/callback',
    authorize_params: {
      scope: 'email openid profile'
    },
    provider_ignores_state: true
  )
end
