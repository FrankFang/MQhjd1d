require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource "验证码" do
  post "/api/v1/validation_codes" do
    parameter :email, type: :string
    let(:email) { '1@qq.com' }
    example "请求发送验证码" do
      expect(UserMailer).to receive(:welcome_email).with(email)
      do_request
      expect(status).to eq 200
      expect(response_body).to eq ' '
    end
  end
end