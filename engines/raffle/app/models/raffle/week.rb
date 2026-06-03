module Raffle
  # One weekly raffle cycle (1 GPU each, 16 total). Exactly one is active at a
  # time (enforced by a partial unique index). Closing a week is a manual admin act.
  class Week < ApplicationRecord
    has_paper_trail

    has_many :credited_referrals, class_name: "Raffle::Referral",
             foreign_key: :credited_week_id, dependent: :nullify, inverse_of: :credited_week

    enum :status, { active: "active", archived: "archived" }, prefix: :status

    validates :status, presence: true
    validates :number, presence: true, uniqueness: true,
              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 16 }

    scope :chronological, -> { order(:number) }

    # The single open week tickets currently accrue to.
    def self.current
      status_active.take
    end

    # { participant_id => total_tickets } for verified referrals credited here.
    def standings
      credited_referrals.status_verified
                        .group(:participant_id)
                        .sum(:tickets_awarded)
    end

    # Ranked [participant, tickets] for the public leaderboard, highest first.
    def leaderboard(limit: 25, standings: self.standings)
      ranked = standings.sort_by { |_id, tickets| -tickets }
      return [] if ranked.empty?

      participants = Raffle::Participant.where(id: ranked.map(&:first)).index_by(&:id)
      ranked.filter_map { |id, tickets| [ participants[id], tickets ] if participants[id] }
            .first(limit)
    end

    # 1-based standing of a participant. Nil if they have no tickets.
    def rank_for(participant, standings: self.standings)
      return nil unless participant

      mine = standings[participant.id].to_i
      return nil if mine.zero?

      standings.values.count { |tickets| tickets > mine } + 1
    end

    def participant_count
      credited_referrals.status_verified.distinct.count(:participant_id)
    end
  end
end
