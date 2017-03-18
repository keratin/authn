module AuthNSession
  extend ActiveSupport::Concern

  NAME = 'authn'

  included do
    include ActionController::Cookies
  end

  private def establish_session(account_id, audience)
    # avoid any potential session fixation. whatever session they had before can't be trusted.
    RefreshToken.revoke(authn_session[:token]) if authn_session[:token]

    # NOTE: the cookie is not set to expire. the sessionjwt is not set to expire. but the refresh
    #       token within the jwt within the cookie will expire.
    cookies[NAME] = {
      value: SessionJWT.generate(account_id, audience),
      path: Rails.application.config.mounted_path,
      secure: Rails.application.config.force_ssl,
      httponly: true
    }

    @authn_session = nil
  end

  private def authn_session
    @authn_session ||= SessionJWT.decode(cookies[NAME])
  end
end
