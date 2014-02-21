class InitController < ApplicationController
  def init_script
    @session_id = request.cookies[Rees46.cookie_name] || params[Rees46.cookie_name]

    @session = Session.find_by(uniqid: @session_id)

    if @session.present?
      @user = @session.user
    else
      @session = Session.create_with_uniqid_and_user(useragent: request.env['HTTP_USER_AGENT'])
      @user = @session.user
    end

    @ab_testing_group = @user.ab_testing_group

    render text: "REES46.initServer('#{@session.uniqid}', '#{Rees46.base_url}', #{@ab_testing_group});"
  end
end
