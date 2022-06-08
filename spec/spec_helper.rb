require 'rspec_api_documentation'

module RequestTestHelper
  def sign_in(user)
    post '/api/v1/session', params: {email: user.email, code: '123456'}
    json = JSON.parse response.body
    {Authorization: "Bearer #{json['jwt']}"}
  end
end

RspecApiDocumentation.configure do |config|
  config.request_body_formatter = :json
end
RSpec.configure do |config|
  config.include RequestTestHelper, type: :request
  config.before(:each) do |spec|
    if spec.metadata[:type].equal? :acceptance
      header 'Accept', 'application/json'
      header 'Content-Type', 'application/json'
    end
  end
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
end
