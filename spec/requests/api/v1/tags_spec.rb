require 'rails_helper'

RSpec.describe "Api::V1::Tags", type: :request do
  describe "获取标签" do
    it "未登录获取标签" do
      get '/api/v1/tags'
      expect(response).to have_http_status(401)
    end
    it "登录后获取标签" do
      user = User.create email: '1@qq.com'
      another_user = User.create email: '2@qq.com'
      11.times do |i| Tag.create name: "tag#{i}", user_id: user.id, sign: 'x' end
      11.times do |i| Tag.create name: "tag#{i}", user_id: another_user.id, sign: 'x' end

      get '/api/v1/tags', headers: user.generate_auth_header
      expect(response).to have_http_status(200)
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 10

      get '/api/v1/tags', headers: user.generate_auth_header, params: {page: 2}
      expect(response).to have_http_status(200)
      json = JSON.parse response.body
      expect(json['resources'].size).to eq 1
    end
  end
end
