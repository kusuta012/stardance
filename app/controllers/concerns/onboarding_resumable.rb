# Shared logic for resuming or expiring an interrupted signup-wizard session.
#
# A "mid-onboarding" user is a guest who entered the wizard but never reached
# the final name step (onboarded_at still nil). The freshness window is anchored
# on when they started the wizard (created_at).
#
# Gated on the :new_onboarding flag: only when it's on is the wizard the sole
# way to become an onboarded_at-nil guest, so the signal can't be confused with
# project-setup / link-gate guests from the old flow.
module OnboardingResumable
  extend ActiveSupport::Concern

  ONBOARDING_WINDOW = 7.days

  private

  def onboarding_in_progress?(user)
    return false unless Flipper.enabled?(:new_onboarding)

    user&.guest? && user.onboarded_at.nil?
  end

  # Within the active window, anchored on when they first started onboarding.
  def onboarding_fresh?(user)
    user.created_at >= ONBOARDING_WINDOW.ago
  end

  # The first wizard step the user hasn't answered yet.
  def onboarding_resume_path(user)
    return onboarding_birthday_path   if user.age_attestation.blank?
    return onboarding_experience_path if user.experience_level.blank?
    return onboarding_interests_path  if user.interests.blank?

    onboarding_name_path
  end

  # Wipe wizard answers so the flow starts over from the top. The email and
  # placeholder name are kept (email is unique, and the name is still a
  # placeholder because they never finished the name step).
  def restart_onboarding!(user)
    user.update!(
      age_attestation: nil,
      experience_level: nil,
      interests: [],
      onboarded_at: nil
    )
  end
end
