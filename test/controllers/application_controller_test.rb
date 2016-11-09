require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test '#configuration' do
    get app_configuration_path

    assert_response(:success)
    data = JSON.parse(response.body)
    assert data['issuer']
    assert data['jwks_uri']
  end

  test '#keys' do
    get app_keys_path

    assert_response(:success)
    data = JSON.parse(response.body)
    assert_equal 1, data['keys'].length
    assert_equal 'sig', data['keys'][0]['use']
    assert_equal Rails.application.config.auth_signing_alg, data['keys'][0]['alg']
  end
end
