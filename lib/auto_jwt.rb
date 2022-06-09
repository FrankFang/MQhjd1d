class AutoJwt
  def initialize(app)
    @app = app
  end
  def call(env)
    # jwt 跳过以下路径
    return @app.call(env) if ['/api/v1/session','/api/v1/validation_codes'].include? env['PATH_INFO']

    header = env['HTTP_AUTHORIZATION']
    jwt = header.split(' ')[1] rescue ''
    begin
      payload = JWT.decode jwt, Rails.application.credentials.hmac_secret, true, { algorithm: 'HS256' } 
    rescue JWT::ExpiredSignature
      return [401, {}, [JSON.generate({reason: 'token expired'})]]
    rescue  
      return [401, {}, [JSON.generate({reason: 'token invalid'})]]
    end
    env['current_user_id'] = payload[0]['user_id'] rescue nil
    @status, @headers, @response = @app.call(env)
    [@status, @headers, @response]
  end
end