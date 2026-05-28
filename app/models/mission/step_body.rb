# == Schema Information
#
# Table name: mission_step_bodies
#
#  id              :bigint           not null, primary key
#  body            :text             default(""), not null
#  body_updated_at :datetime
#  language        :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  mission_step_id :bigint           not null
#
# Indexes
#
#  index_mission_step_bodies_on_mission_step_id  (mission_step_id)
#  index_mission_step_bodies_unique_language     (mission_step_id, lower((language)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (mission_step_id => mission_steps.id)
#
class Mission::StepBody < ApplicationRecord
  self.table_name = "mission_step_bodies"

  # Intentionally no PaperTrail: every step CRUD writes every step body via
  # the regenerate path, multiplied by language count. The parent
  # Mission::GuideVariant.body is already versioned with the same content
  # (it's a join of all the StepBody markdown), so versioning here would
  # quadruple the audit churn for no recoverable history we don't already
  # have via the variant.

  belongs_to :step, class_name: "Mission::Step",
                    foreign_key: :mission_step_id,
                    inverse_of: :bodies

  validates :language, presence: true, length: { maximum: 64 },
                       uniqueness: { scope: :mission_step_id, case_sensitive: false }
  validates :body, presence: false  # empty bodies are allowed (placeholder)

  before_save :stamp_body_updated_at, if: :body_changed?

  private

  def stamp_body_updated_at
    self.body_updated_at = Time.current
  end
end
