require "securerandom"

module Raffle
  # A person competing in the raffle. Identified by GitHub (independent of the
  # platform's Hack Club login). Owns a referral code and many referrals.
  class Participant < ApplicationRecord
    has_paper_trail

    has_many :referrals, class_name: "Raffle::Referral", dependent: :destroy

    before_validation :assign_code, on: :create

    validates :github_uid, presence: true, uniqueness: true
    validates :github_login, presence: true
    validates :code, presence: true, uniqueness: true

    # Find-or-create from an OmniAuth GitHub payload.
    def self.from_github(auth)
      info = auth.info
      github_uid = auth.uid.to_s
      github_login = info&.nickname.to_s.strip.presence || "github-#{github_uid}"

      participant = find_or_initialize_by(github_uid: github_uid)
      participant.github_login = github_login
      participant.name = info&.name.to_s.strip.presence || github_login
      participant.github_email = info&.email.to_s.strip.downcase.presence
      participant.avatar_url = info&.image
      participant.save!
      participant
    end

    def self.generate_unique_code
      alphabet = "abcdefghjkmnpqrstuvwxyz23456789"
      100.times do
        candidate = 5.times.map { alphabet[SecureRandom.random_number(alphabet.length)] }.join
        return candidate unless exists?(code: candidate)
      end
      raise "could not generate a unique raffle code"
    end

    # Shareable link for a channel (:web -> r-, :discord -> d-).
    def referral_url(channel = :web)
      prefix = channel == :discord ? "d" : "r"
      "https://stardance.space/#{prefix}-#{code}"
    end

    def ticket_count(week)
      return 0 unless week

      referrals.status_verified.where(credited_week_id: week.id).sum(:tickets_awarded)
    end

    def ticket_totals_by_week
      referrals.status_verified
               .where.not(credited_week_id: nil)
               .group(:credited_week_id)
               .sum(:tickets_awarded)
    end

    def pending_referrals
      referrals.status_pending.order(created_at: :desc)
    end

    # Hide self-referrals from the participant entirely.
    def visible_referrals
      referrals.where.not(status: :self_referral)
    end

    private

    def assign_code
      self.code ||= self.class.generate_unique_code
    end
  end
end
