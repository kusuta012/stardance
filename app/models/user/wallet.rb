module User::Wallet
  extend ActiveSupport::Concern

  def balance = ledger_entries.sum(:amount)

  def total_earned = ledger_entries.where("amount > 0").sum(:amount)

  def cached_balance = Rails.cache.fetch(balance_cache_key) { balance }

  def balance_cache_key = "user/#{id}/sidebar_balance"

  def refresh_approx_balance!
    return unless self.class.column_names.include?("approx_balance")

    update_columns(
      approx_balance: balance,
      approx_total_earned: total_earned
    )
  end

  def invalidate_balance_cache!
    Rails.cache.delete(balance_cache_key)
    refresh_approx_balance!
  end

  def grant_email
    hcb_email.presence || email
  end
end
