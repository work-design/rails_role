module TheRole::Controller

  def role_access_denied
    access_denied_method = TheRole.config.access_denied_method
    return send(access_denied_method) if access_denied_method && respond_to?(access_denied_method)

    default_access_denied_response
  end

  private
  def for_ownership_check obj
    @owner_check_object = obj
  end

  def role_required
    role_access_denied unless the_role_user.has_role? controller_path, action_name
  end

  def owner_required
    role_access_denied unless the_role_user.owner? @owner_check_object
  end

  def default_access_denied_response
    access_denied_msg = t(:access_denied, scope: :the_role)

    if request.xhr?
      render json: {
        errors: { the_role: [ access_denied_msg ] },

        controller_name:      controller_path,
        action_name:          action_name,
        has_access_to_action: the_role_user.try(:has_role?, controller_path, action_name),

        the_role_user: { id: the_role_user.try(:id) },

        owner_check_object: {
          owner_check_object_id:    @owner_check_object.try(:id),
          owner_check_object_class: @owner_check_object.try(:class).try(:to_s)
        },

        has_access_to_object: the_role_user.try(:owner?, @owner_check_object)
      }, status: 401
    else
      if request.referer.present?
        redirect_to :back, flash: { error: access_denied_msg }
      else
        redirect_to root_path, flash: { error: access_denied_msg }
      end
    end
  end

  def the_role_user
    current_user
  end

end
