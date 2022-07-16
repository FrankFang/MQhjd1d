require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource "标签" do
  authentication :basic, :auth
  let(:current_user) { create :user }
  let(:auth) { "Bearer #{current_user.generate_jwt}" }
  get "/api/v1/tags/:id" do
    let (:tag) { create :tag, user: current_user }
    let (:id) { tag.id }
    with_options :scope => :resource do
      response_field :id, 'ID'
      response_field :name, "名称"
      response_field :sign, "符号"
      response_field :user_id, "用户ID"
      response_field :deleted_at, "删除时间"
    end
    example "获取标签" do
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resource']['id']).to eq tag.id
    end
  end
  get "/api/v1/tags" do
    parameter :page, '页码'
    parameter :kind, '类型', in: ['expenses', 'income']
    with_options :scope => :resources do
      response_field :id, 'ID'
      response_field :name, "名称"
      response_field :sign, "符号"
      response_field :user_id, "用户ID"
      response_field :deleted_at, "删除时间"
    end
    example "获取标签列表" do
      create_list :tag, Tag.default_per_page+1, user: current_user
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resources'].size).to eq Tag.default_per_page
    end
  end
  post "/api/v1/tags" do
    parameter :name, '名称', required: true
    parameter :sign, '符号', required: true
    parameter :kind, '类型', required: true, in: ['expenses', 'income']
    with_options :scope => :resource do
      response_field :id, 'ID'
      response_field :name, "名称"
      response_field :sign, "符号"
      response_field :user_id, "用户ID"
      response_field :deleted_at, "删除时间"
    end
    let (:name) { 'x' }
    let (:sign) { 'x' }
    let (:kind) { 'income' }
    example "创建标签" do
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resource']['name']).to eq name
      expect(json['resource']['sign']).to eq sign
    end
  end
  patch "/api/v1/tags/:id" do
    let (:tag) { create :tag, user: current_user }
    let (:id) { tag.id }
    parameter :name, '名称'
    parameter :sign, '符号'
    with_options :scope => :resource do
      response_field :id, 'ID'
      response_field :name, "名称"
      response_field :sign, "符号"
      response_field :user_id, "用户ID"
      response_field :deleted_at, "删除时间"
    end
    let (:name) { 'y' }
    let (:sign) { 'y' }
    example "修改标签" do
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resource']['name']).to eq name
      expect(json['resource']['sign']).to eq sign
    end
  end
  delete "/api/v1/tags/:id" do
    let (:tag) { create :tag, user: current_user }
    let (:id) { tag.id }
    example "删除标签" do
      do_request
      expect(status).to eq 200
    end
  end
end
