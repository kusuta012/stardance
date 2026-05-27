module Certification
  class YswsController < Admin::ApplicationController
    def index
      authorize :admin, :access_reviews?

      @reviews = Certification::Ysws
        .where(reviewed_at: nil)
        .includes(:project, :user)
        .order(created_at: :asc)
    end

    def show
      authorize :admin, :access_reviews?

      @review = Certification::Ysws
        .includes(:project, :user, :reviewer, devlog_reviews: { post_devlog: :attachments_attachments })
        .find(params[:id])

      # Calculate time stats
      devlog_minutes = @review.devlog_reviews.map(&:original_minutes).compact

      @stats = {
        total_minutes: devlog_minutes.sum,
        avg_minutes: devlog_minutes.any? ? (devlog_minutes.sum.to_f / devlog_minutes.count) : 0,
        max_minutes: devlog_minutes.max || 0,
        one_hour_plus_count: devlog_minutes.count { |m| m >= 60 }
      }

      # Fetch platform contributions once to avoid multiple API calls
      @repo_info = helpers.parse_repo_info(@review.project.repo_url)
      if @repo_info
        platform = @repo_info[:platform]
        username = @repo_info[:username]
        @contribution_data = Admin::ReviewPlatformService.fetch_contributions(platform, username)
      end
    end

    def report_fraud
      authorize :admin, :access_reviews?

      @review = Certification::Ysws.find(params[:id])

      report = Project::Report.new(
        project_id: @review.project_id,
        reporter_id: current_user.id,
        reason: "YSWS project flag",
        details: params[:details],
        status: :pending
      )

      if report.save
        render json: { success: true, message: "Report submitted successfully" }, status: :created
      else
        render json: { success: false, errors: report.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end