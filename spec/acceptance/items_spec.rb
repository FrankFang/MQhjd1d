require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource "账目" do
  let(:current_user) { User.create email: '1@qq.com' }
  let(:auth) { "Bearer #{current_user.generate_jwt}" }
  get "/api/v1/items" do
    authentication :basic, :auth
    parameter :page, '页码'
    parameter :created_after, '创建时间起点（筛选条件）' 
    parameter :created_before, '创建时间终点（筛选条件）' 
    with_options :scope => :resources do
      response_field :id, 'ID'
      response_field :amount, "金额（单位：分）"
    end
    let(:created_after) { Time.now - 10.days }
    let(:created_before) { Time.now + 10.days }
    example "获取账目" do
      tag = Tag.create name: 'x', sign:'x', user_id: current_user.id
      11.times do 
        Item.create! amount: 100, happen_at: '2020-10-30', tags_id: [tag.id], 
          user_id: current_user.id 
      end
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resources'].size).to eq 10
    end
  end

  post "/api/v1/items" do
    authentication :basic, :auth
    parameter :amount, '金额（单位：分）', required: true
    parameter :kind, '类型', required: true, enum: ['expenses', 'income']
    parameter :happen_at, '发生时间', required: true
    parameter :tags_id, '标签列表（只传ID）', required: true
    with_options :scope => :resource do
      response_field :id
      response_field :amount
      response_field :kind
      response_field :happen_at
      response_field :tags_id
    end
    let(:amount) { 9900 }
    let(:kind) { 'expenses' }
    let(:happen_at) { '2020-10-30T00:00:00+08:00' }
    let(:tags) { (0..1).map{Tag.create name: 'x', sign:'x', user_id: current_user.id} }
    let(:tags_id) { tags.map(&:id) }
    let(:happen_at) { '2020-10-30T00:00:00+08:00' }
    example "创建账目" do
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resource']['amount']).to eq amount
    end
  end
end