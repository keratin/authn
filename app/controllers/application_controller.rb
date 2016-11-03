require 'json_envelope'

class ApplicationController < ActionController::API

  # when HTTP_REFERER exists, it's a great way to prevent CSRF attacks.
  #
  # an experiment performed in http://seclab.stanford.edu/websec/csrf/csrf.pdf found the
  # header existed for 99.9% of users over HTTPS, even cross-origin. the header appears
  # to be primarily suppressed at the network level, not the user agent.
  #
  # if this is ever determined insufficient, the backup plan is a custom header set by
  # compatible javascript. stay stateless!
  private def require_trusted_referrer
    referrer_host = begin
      URI.parse(request.referer).host
    rescue URI::InvalidURIError
    end

    return if Configs[:auth][:trusted_hosts].include?(referrer_host)
    render status: :forbidden, json: JSONEnvelope.errors('referer' => 'is not a trusted host')
  end

end
