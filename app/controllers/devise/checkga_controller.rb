require 'digest/sha2'

class Devise::CheckgaController < Devise::SessionsController
  include Devise::Controllers::Helpers

  prepend_before_filter :require_no_authentication, :only => [:show, :update]
  before_filter :set_tmp_id

  def show
    if @tmpid.nil?
      redirect_to :root
    else
      render :show
    end
  end

  def update
    resource = resource_class.find_by_gauth_tmp @tmp_id
    token = params[resource_name]['token']

    # Redirect to root
    redirect_to :root if resource.nil?

    # Sign in using Gauth token
    if resource.validate_token(token.to_i)
      remember_me(resource) if params[:remember_me]
      session[:gauth_tmp_id] = nil

      set_flash_message(:notice, :signed_in) if is_navigational_format?
      sign_in(resource_name, resource)

      respond_with resource, :location => after_sign_in_path_for(resource)

    # Display error if Gauth token authentication fails
    else
      flash[:alert] = I18n.t('token_invalid', {:scope => 'devise'})
      render :show
    end
  end

  private

  def set_tmp_id
    @tmpid = session[:gauth_tmp_id]
  end

  # Set a remember me token if params[:remember_me] is not nil or false.
  def remember_me(resource)
    remember_key = Digest::SHA2.new << "#{resource_name}-#{resource.id}"
    remember_value = Digest::SHA2.new << resource.gauth_secret

    cookies.signed[remember_key.to_s] = {
      value: remember_value.to_s,
      expires_at: Devise.remember_gauth_for.from_now
    }
  end
end