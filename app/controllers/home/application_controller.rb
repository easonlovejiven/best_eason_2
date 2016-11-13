class Home::ApplicationController < ApplicationController
	layout 'home/application'

	private

	def authorized?
		@enable_lazyload = true

		!!@current_user
	end
end
