module Admin
  class ReviewsController < Admin::ApplicationController
    def index
      authorize :admin, :access_reviews?

      @reviews = YswsReview
        .where(reviewed_at: nil)
        .includes(:project, :user)
        .order(created_at: :asc)
    end

    def show
      authorize :admin, :access_reviews?

      @review = YswsReview
        .includes(:project, :user, :reviewer, devlog_reviews: { post_devlog: :attachments_attachments })
        .find(params[:id])
    end
  end
end