class Api::V1::MesController < ApplicationController
  def show
    header = request.headers["Authorization"]
    jwt = header.split(' ')[1] rescue ''
    payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: 'HS256' } rescue nil
    return head 400 if payload.nil?
    user_id = payload[0]['user_id'] rescue nil
    user = User.find user_id
    return head 404 if user.nil?
    render json: { resource: user }
  end
end
