# == Schema Information
#
# Table name: devlog_reviews
#
#  id               :bigint           not null, primary key
#  approved_minutes :integer
#  justification    :text
#  original_minutes :integer
#  status           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  post_devlog_id   :bigint           not null
#  ysws_review_id   :bigint           not null
#
# Indexes
#
#  index_devlog_reviews_on_post_devlog_id  (post_devlog_id)
#  index_devlog_reviews_on_ysws_review_id  (ysws_review_id)
#
# Foreign Keys
#
#  fk_rails_...  (post_devlog_id => post_devlogs.id)
#  fk_rails_...  (ysws_review_id => ysws_reviews.id)
#
class DevlogReview < ApplicationRecord
  belongs_to :post_devlog, class_name: "Post::Devlog"
  belongs_to :ysws_review

  # Status enum for tracking review state
  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected"
  }, default: :pending

  # Validations
  validates :original_minutes, numericality: { greater_than_or_equal_to: 0 }, allow_nil: false
  validates :approved_minutes, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # When approved, must have non-negative minutes
  validates :approved_minutes,
    presence: true,
    numericality: { greater_than_or_equal_to: 0 },
    if: :approved?

  # When rejected, approved_minutes should be 0
  validates :approved_minutes,
    numericality: { equal_to: 0 },
    allow_nil: true,
    if: :rejected?

  # State transition methods
  def approve!(minutes, justification_text = nil)
    raise "Cannot approve - already reviewed" if approved? || rejected?
    raise "Approved minutes must be positive" if minutes.to_i <= 0

    update!(
      status: "approved",
      approved_minutes: minutes,
      justification: justification_text
    )
  end

  def reject!(justification_text)
    raise "Cannot reject - already reviewed" if approved? || rejected?
    raise "Justification required for rejection" if justification_text.blank?

    update!(
      status: "rejected",
      approved_minutes: 0,
      justification: justification_text
    )
  end

  def reset_to_pending!
    update!(
      status: "pending",
      approved_minutes: nil,
      justification: nil
    )
  end

  # Helper method to check if review has been completed
  def reviewed?
    approved? || rejected?
  end

  # Get display minutes (approved if reviewed, original if pending)
  def display_minutes
    reviewed? ? approved_minutes : original_minutes
  end
end
