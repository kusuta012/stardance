module Admin
  module Raffles
    class WeeksController < Admin::ApplicationController
      before_action :set_week, only: [ :show, :close, :draw_winner ]

      def index
        authorize :admin, :access_raffles?
        @weeks = ::Raffle::Week.chronological.includes(:winner_participant)
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

      def draw_winner
        authorize :admin, :access_raffles?
        winner = ::Raffle::DrawWinnerService.run(@week)

        if winner
          redirect_to admin_raffles_week_path(@week),
                      notice: "Winner drawn: #{winner.github_login} (#{winner.ticket_count(@week)} tickets)."
        else
          redirect_to admin_raffles_week_path(@week), alert: "No tickets this week — nothing to draw."
        end
      end

      private

      def set_week
        @week = ::Raffle::Week.includes(:winner_participant).find(params[:id])
      end
    end
  end
end
