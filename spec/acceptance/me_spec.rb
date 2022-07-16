require "rails_helper"
require "rspec_api_documentation/dsl"

resource "当前用户" do
  let(:current_user) { create :user }
  let(:auth) { "Bearer #{current_user.generate_jwt}" }
  get "/api/v1/me" do
    authentication :basic, :auth
    example "获取当前用户" do
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json["resource"]["id"]).to eq current_user.id
    end
  end
end
