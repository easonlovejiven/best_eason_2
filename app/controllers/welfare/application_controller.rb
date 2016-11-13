class Welfare::ApplicationController < ApplicationController
  include ApplicationHelper
  layout 'home/application'

  def authorized?
    !!@current_user
  end
end
