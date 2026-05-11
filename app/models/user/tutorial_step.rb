class User
  TutorialStep = Data.define(:slug, :name, :description, :icon, :link, :deps, :verb, :video_url) do
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    def initialize(params = {})
      params[:deps] ||= nil
      params[:verb] ||= :get
      params[:video_url] ||= nil
      super(**params)
    end

    # N.B.: this is not a proper graph, so be careful with your preconditions!
    # revoking a tutorial step (i.e. on delete) does not propagate up through dependency chains.
    Dep = Data.define(:slug, :hint) do
      def satisfied?(s)
        s.include?(slug)
      end
    end

    self::ALL = [
    ].freeze

    self::SLUGGED = self::ALL.index_by(&:slug).freeze
    self::ALL_SLUGS = self::SLUGGED.keys.freeze

    class << self
      def all
        self::ALL
      end

      def slugged
        self::SLUGGED
      end

      def all_slugs
        self::ALL_SLUGS
      end

      def find(s)
        self::SLUGGED.fetch(s.to_sym)
      end

      # console affordance - don't let me catch you using this in application code
      alias_method :[], :find
    end

    def deps_satisfied?(s)
      return true unless deps&.any?

      deps.all? { |d| d.satisfied?(s) }
    end

    def to_param
      slug
    end

    def persisted?
      true
    end
  end
end
