module AccessControl
  def authenticated?
    # SECURITY NOTE
    #
    # beware timing attacks! we must not only compare username and password securely to avoid hints
    # about partial matches, we must also be sure to compare both each time and avoid giving away
    # a correct guess on the username.
    !!ActionController::HttpAuthentication::Basic.authenticate(request) do |username, password|
      [
        SecureCompare.compare(username, Rails.application.config.api_username),
        SecureCompare.compare(password, Rails.application.config.api_password)
      ].all?
    end
  end

  # when HTTP_REFERER exists, it's a great way to prevent CSRF attacks.
  #
  # an experiment performed in http://seclab.stanford.edu/websec/csrf/csrf.pdf found the header
  # existed for 99.9% of users over HTTPS, even cross-origin. the header appears to be primarily
  # suppressed at the network level, not the user agent, and ssl prevents that.
  #
  # native agents may need to fake this header.
  def referred?
    !!Rails.application.config.application_domains.include?(requesting_audience)
  end

  # TODO: decide how to manage this shared dependency from ApplicationController
  # def requesting_audience
end
