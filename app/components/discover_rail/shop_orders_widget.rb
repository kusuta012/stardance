# frozen_string_literal: true

module DiscoverRail
  class ShopOrdersWidget < BaseWidget
    register_as :shop_orders

    def orders
      context[:sidebar_orders] || []
    end

    def render?
      user.present?
    end
  end
end
