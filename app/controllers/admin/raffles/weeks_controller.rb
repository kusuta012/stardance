module Admin
  module Raffles
    class WeeksController < Admin::ApplicationController
      before_action :set_week, only: [ :show, :close ]

      def index
        authorize :admin, :access_raffles?
        @weeks = ::Raffle::Week.chronological
      end

      def show
        authorize :admin, :access_raffles?
        standings = @week.standings
        @standings = @week.leaderboard(limit: standings.size, standings: standings)
      end

      def close
        authorize :admin, :access_raffles?

        unless @week.status_active?
          return redirect_to admin_raffles_week_path(@week), alert: "Only the active week can be closed."
        end

        next_week = ::Raffle::Weeks::Close.run(@week)
        notice = next_week ? "Week #{@week.number} archived. Week #{next_week.number} is now open." :
                             "Week #{@week.number} archived. That was the final week — the program is complete."
        redirect_to admin_raffles_weeks_path, notice: notice
      end

      private

      def set_week
        @week = ::Raffle::Week.find(params[:id])
      end
    end
  end
end
