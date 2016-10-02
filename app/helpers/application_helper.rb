module ApplicationHelper

	def navbar
		content_tag :nav, class: %w(navbar navbar-default) do
  			content_tag :div, class: "container-fluid" do
  				content_tag :div, class: "navbar-header" do
  					link_to "http://bigcommerce.com", class: "navbar-brand", target: "_blank" do
  						image_tag "BigCommerce_logo_dark.png", alt: "Brand", width: 125
  					end
  				end
  			end
  		end
	end

	def centered_panel id
		content_tag :div, class: %w(row row-centered) do
			content_tag :div, class: %(col-xs-10 col-centered) do
				content_tag :div, class: %w(panel panel-default) do
					content_tag :div, nil, class: "panel-body", id: id
				end
			end
		end
	end
end
