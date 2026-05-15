# frozen_string_literal: true

module Posts
  class ComposerComponent < ViewComponent::Base
    delegate :inline_svg_tag, to: :helpers

    attr_reader :post, :current_user, :projects, :selected_project

    def initialize(post:, current_user:, projects:, selected_project:)
      @post = post
      @current_user = current_user
      @projects = projects
      @selected_project = selected_project
    end

    def enabled?
      selected_project.present?
    end

    def hackatime_linked?
      selected_project&.hackatime_keys&.present?
    end

    def preview_time_url
      helpers.preview_time_project_devlogs_path(selected_project)
    end

    def visible_projects
      projects.first(3)
    end
  end
end
