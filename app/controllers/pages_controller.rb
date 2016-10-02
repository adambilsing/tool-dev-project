class PagesController < ApplicationController

	def show_call_data
		
		respond_to do |format|
			format.html
			format.json do
				render json: CallData.new(params).data
			end
		end
	end
end
