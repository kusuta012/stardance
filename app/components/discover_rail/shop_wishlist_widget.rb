# frozen_string_literal: true

module DiscoverRail
  class ShopWishlistWidget < BaseWidget
    register_as :shop_wishlist

    def balance
      context[:user_balance] || 0
    end

    def render?
      true
    end
  end
end
