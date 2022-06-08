class AutoJwt
  def initialize(app)
    @app = app
  end
  def call(env)
    header = env['HTTP_AUTHORIZATION']
    jwt = header.split(' ')[1] rescue ''
    payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: 'HS256' } rescue nil
    env['current_user_id'] = payload[0]['user_id'] rescue nil
    @status, @headers, @response = @app.call(env)
    [@status, @headers, @response]
  end
end