class Project::Magic
  include ActiveModel::Model

  attr_reader :project

  def initialize(project)
    @project = project
  end

  def grant(user)
    return false unless ensure_not_fire
    return false unless perform(user, "mark_fire") do
      fire_event = Post::FireEvent.create!(body: fire_event_body(user))
      project.posts.create!(user: user, postable: fire_event)
      project.update!(marked_fire_at: Time.current, marked_fire_by: user)
    end
    enqueue_magic_jobs
    true
  end

  def revoke(user)
    return false unless ensure_fire
    perform(user, "unmark_fire") do
      project.update!(marked_fire_at: nil, marked_fire_by: nil)
    end
  end

  private

  def ensure_not_fire
    return true unless project.fire?
    errors.add(:base, "Project is already marked as Super Star.")
    false
  end

  def ensure_fire
    return true if project.fire?
    errors.add(:base, "Project is not marked as Super Star.")
    false
  end

  def perform(user, event)
    PaperTrail.request(whodunnit: user.id) do
      Project.transaction do
        project.paper_trail_event = event
        yield
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.merge!(e.record.errors)
    false
  end

  def fire_event_body(user)
    "⭐ #{user.display_name} marked your project as a Super Star! As a prize for your great work, look out for a bonus prize in the mail :)"
  end

  def enqueue_magic_jobs
    Project::PostToMagicJob.perform_later(project)
    Project::MagicHappeningLetterJob.perform_later(project)
    project.users.each do |user|
      SendSlackDmJob.perform_later(
        user.slack_id,
        blocks_path: "notifications/projects/super_star",
        locals: { project: project },
      )
    end
  end
end
