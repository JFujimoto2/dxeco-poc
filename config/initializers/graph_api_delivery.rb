require_relative "../../lib/graph_api_delivery"

ActionMailer::Base.add_delivery_method :graph_api, GraphApiDelivery
