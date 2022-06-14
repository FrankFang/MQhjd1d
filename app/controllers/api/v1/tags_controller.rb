class Api::V1::TagsController < ApplicationController
  def index
    current_user = User.find request.env['current_user_id']
    return render status: 401 if current_user.nil?  
    tags = Tag.where(user_id: current_user.id).page(params[:page])
    render json: {resources: tags, pager: {
      page: params[:page] || 1,
      per_page: Tag.default_per_page,
      count: Tag.count
    }}
  end
  def create
    current_user = User.find request.env['current_user_id']
    return render status: 401 if current_user.nil?  

    tag = Tag.new name: params[:name], sign: params[:sign], user_id: current_user.id
    if tag.save
      render json: {resource: tag}, status: :ok
    else
      render json: {errors: tag.errors}, status: :unprocessable_entity
    end
  end
end
