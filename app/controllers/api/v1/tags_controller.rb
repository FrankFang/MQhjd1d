class Api::V1::TagsController < ApplicationController
  def index
    current_user = User.find request.env['current_user_id']
    return render status: :not_found if current_user.nil?  
    tags = Tag.where(user_id: current_user.id).page(params[:page])
    render json: {resources: tags}
  end
end
