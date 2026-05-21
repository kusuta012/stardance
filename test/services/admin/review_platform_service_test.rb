require "test_helper"

module Admin
  class ReviewPlatformServiceTest < ActiveSupport::TestCase
    test "fetch_contributions returns error for blank username" do
      result = ReviewPlatformService.fetch_contributions("github", "")
      assert_equal :no_username, result[:error]
    end

    test "fetch_contributions returns error for unsupported platform" do
      result = ReviewPlatformService.fetch_contributions("unknown", "testuser")
      assert_equal :unsupported_platform, result[:error]
    end

    test "fetch_contributions returns error for gitlab (not yet implemented)" do
      result = ReviewPlatformService.fetch_contributions("gitlab", "testuser")
      assert_equal :unsupported_platform, result[:error]
    end

    test "fetch_contributions returns error for codeberg (not yet implemented)" do
      result = ReviewPlatformService.fetch_contributions("codeberg", "testuser")
      assert_equal :unsupported_platform, result[:error]
    end

    # Note: The following tests would require mocking HTTP requests
    # Uncomment and implement with WebMock or VCR when needed

    # test "fetch_github_contributions returns total for valid user" do
    #   # Mock HTTP response here
    #   result = ReviewPlatformService.fetch_contributions("github", "hackclub")
    #   assert result[:total].is_a?(Integer)
    #   assert result[:total] >= 0
    # end

    # test "fetch_github_contributions returns org_repo for 404" do
    #   # Mock 404 response here
    #   result = ReviewPlatformService.fetch_contributions("github", "nonexistentorg123")
    #   assert_equal :org_repo, result[:error]
    # end

    # test "fetch_github_contributions handles timeout gracefully" do
    #   # Mock timeout here
    #   result = ReviewPlatformService.fetch_contributions("github", "testuser")
    #   assert_equal :timeout, result[:error]
    # end
  end
end
