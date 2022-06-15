require 'rails_helper'

RSpec.describe "Api::V1::Tags", type: :request do
  describe "获取标签列表" do
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
  describe '获取标签' do
    it "未登录获取标签" do
      user = User.create email: '1@qq.com'
      tag = Tag.create name: 'tag1', user_id: user.id, sign: 'x'
      get "/api/v1/tags/#{tag.id}"
      expect(response).to have_http_status(401)
    end
    it '登录后获取标签' do
      user = User.create email: '1@qq.com'
      tag = Tag.create name: 'tag1', user_id: user.id, sign: 'x'
      get "/api/v1/tags/#{tag.id}", headers: user.generate_auth_header
      expect(response).to have_http_status(200)
      json = JSON.parse response.body
      expect(json['resource']['id']).to eq tag.id
    end
    it '登录后获取不属于自己的标签' do
      user = User.create email: '1@qq.com'
      another_user = User.create email: '2@qq.com'
      tag = Tag.create name: 'tag1', user_id: another_user.id, sign: 'x'
      get "/api/v1/tags/#{tag.id}", headers: user.generate_auth_header
      expect(response).to have_http_status(403)
    end
  end
  describe '创建标签' do
    it '未登录创建标签' do
      post '/api/v1/tags', params: {name: 'x', sign: 'x'}
      expect(response).to have_http_status(401)
    end
    it '登录后创建标签' do
      user = User.create email: '1@qq.com'
      post '/api/v1/tags', params: {name: 'name', sign: 'sign'}, headers: user.generate_auth_header
      expect(response).to have_http_status(200)
      json = JSON.parse response.body
      expect(json['resource']['name']).to eq 'name'
      expect(json['resource']['sign']).to eq 'sign'
    end
    it '登录后创建标签失败，因为没填 name' do
      user = User.create email: '1@qq.com'
      post '/api/v1/tags', params: {sign: 'sign'}, headers: user.generate_auth_header
      expect(response).to have_http_status(422)
      json = JSON.parse response.body
      expect(json['errors']['name'][0]).to eq "can't be blank"
    end
    it '登录后创建标签失败，因为没填 sign' do
      user = User.create email: '1@qq.com'
      post '/api/v1/tags', params: {name: 'name'}, headers: user.generate_auth_header
      expect(response).to have_http_status(422)
      json = JSON.parse response.body
      expect(json['errors']['sign'][0]).to eq "can't be blank"
    end
  end

  describe '更新标签' do
    it '未登录修改标签' do
      user = User.create email: '1@qq.com'
      tag = Tag.create name: 'x', sign: 'x', user_id: user.id
      patch "/api/v1/tags/#{tag.id}", params: {name: 'y', sign: 'y'}
      expect(response).to have_http_status(401)
    end
    it '登录后修改标签' do
      user = User.create email: '1@qq.com'
      tag = Tag.create name: 'x', sign: 'x', user_id: user.id
      patch "/api/v1/tags/#{tag.id}", params: {name: 'y', sign: 'y'}, headers: user.generate_auth_header
      expect(response).to have_http_status(200)
      json = JSON.parse response.body
      expect(json['resource']['name']).to eq 'y'
      expect(json['resource']['sign']).to eq 'y'
    end
    it '登录后部分修改标签' do
      user = User.create email: '1@qq.com'
      tag = Tag.create name: 'x', sign: 'x', user_id: user.id
      patch "/api/v1/tags/#{tag.id}", params: {name: 'y'}, headers: user.generate_auth_header
      expect(response).to have_http_status(200)
      json = JSON.parse response.body
      expect(json['resource']['name']).to eq 'y'
      expect(json['resource']['sign']).to eq 'x'
    end
  end

  describe '删除标签' do
    it '未登录删除标签' do
      user = User.create email: '1@qq.com'
      tag = Tag.create name: 'x', sign: 'x', user_id: user.id
      delete "/api/v1/tags/#{tag.id}"
      expect(response).to have_http_status(401)
    end
    it '登录后删除标签' do
      user = User.create email: '1@qq.com'
      tag = Tag.create name: 'x', sign: 'x', user_id: user.id
      delete "/api/v1/tags/#{tag.id}", headers: user.generate_auth_header
      expect(response).to have_http_status(200)
      tag.reload
      expect(tag.deleted_at).not_to eq nil
    end
    it '登录后删除别人的标签' do
      user = User.create email: '1@qq.com'
      other = User.create email: '2@qq.com'
      tag = Tag.create name: 'x', sign: 'x', user_id: other.id
      delete "/api/v1/tags/#{tag.id}", headers: user.generate_auth_header
      expect(response).to have_http_status(403)
    end
  end
end
