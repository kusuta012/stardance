module Admin
  class ReviewsController < Admin::ApplicationController
    def index
      authorize :admin, :access_reviews?

      @reviews = YswsReview
        .where(reviewed_at: nil)
        .includes(:project, :user)
        .order(created_at: :asc)
    end
  end
end