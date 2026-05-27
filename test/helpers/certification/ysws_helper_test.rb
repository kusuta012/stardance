require "test_helper"

class Certification::YswsHelperTest < ActionView::TestCase
  test "parse_repo_info extracts GitHub username" do
    result = parse_repo_info("https://github.com/hackclub/stardance")

    assert_equal "github", result[:platform]
    assert_equal "GitHub", result[:platform_name]
    assert_equal "hackclub", result[:username]
    assert_equal "github", result[:icon]
  end

  test "parse_repo_info extracts GitLab username" do
    result = parse_repo_info("https://gitlab.com/gitlab-org/gitlab")

    assert_equal "gitlab.com", result[:platform]
    assert_equal "GitLab", result[:platform_name]
    assert_equal "gitlab-org", result[:username]
    assert_equal "gitlab.com", result[:icon]
  end

  test "parse_repo_info extracts Codeberg username" do
    result = parse_repo_info("https://codeberg.org/forgejo/forgejo")

    assert_equal "codeberg.org", result[:platform]
    assert_equal "Codeberg", result[:platform_name]
    assert_equal "forgejo", result[:username]
    assert_equal "codeberg.org", result[:icon]
  end

  test "parse_repo_info extracts Bitbucket username" do
    result = parse_repo_info("https://bitbucket.org/atlassian/python-bitbucket")

    assert_equal "bitbucket.org", result[:platform]
    assert_equal "Bitbucket", result[:platform_name]
    assert_equal "atlassian", result[:username]
    assert_equal "bitbucket.org", result[:icon]
  end

  test "parse_repo_info extracts SourceHut username" do
    result = parse_repo_info("https://git.sr.ht/~sircmpwn/aerc")

    assert_equal "git.sr.ht", result[:platform]
    assert_equal "SourceHut", result[:platform_name]
    assert_equal "~sircmpwn", result[:username]
    assert_equal "git.sr.ht", result[:icon]
  end

  test "parse_repo_info handles GitHub URL with .git extension" do
    result = parse_repo_info("https://github.com/hackclub/stardance.git")

    assert_equal "github", result[:platform]
    assert_equal "hackclub", result[:username]
  end

  test "parse_repo_info handles GitHub URL with trailing slash" do
    result = parse_repo_info("https://github.com/hackclub/stardance/")

    assert_equal "github", result[:platform]
    assert_equal "hackclub", result[:username]
  end

  test "parse_repo_info handles unknown git hosting" do
    result = parse_repo_info("https://git.example.com/myuser/myrepo")

    assert_equal "git", result[:platform]
    assert_equal "git.example.com", result[:platform_name]
    assert_equal "myuser", result[:username]
    assert_equal "git", result[:icon]
  end

  test "parse_repo_info returns nil for blank URL" do
    assert_nil parse_repo_info("")
    assert_nil parse_repo_info(nil)
  end

  test "parse_repo_info returns nil for invalid URL" do
    assert_nil parse_repo_info("not a valid url")
  end

  test "parse_repo_info returns nil for URL without path" do
    assert_nil parse_repo_info("https://github.com")
    assert_nil parse_repo_info("https://github.com/")
  end

  # Contribution fetching tests
  test "fetch_platform_contributions returns nil for blank platform" do
    assert_nil fetch_platform_contributions("", "username")
  end

  test "fetch_platform_contributions returns nil for blank username" do
    assert_nil fetch_platform_contributions("github", "")
  end

  # Note: The following tests would require mocking the service
  # Uncomment and implement with appropriate mocks when needed

  # test "fetch_platform_contributions returns formatted string for valid contributions" do
  #   # Mock service to return { total: 31 }
  #   result = fetch_platform_contributions("github", "hackclub")
  #   assert_equal "31 contributions", result
  # end

  # test "fetch_platform_contributions returns org repo for organization accounts" do
  #   # Mock service to return { error: :org_repo }
  #   result = fetch_platform_contributions("github", "orgaccount")
  #   assert_equal "org repo", result
  # end

  # test "fetch_platform_contributions returns nil for timeouts" do
  #   # Mock service to return { error: :timeout }
  #   result = fetch_platform_contributions("github", "username")
  #   assert_nil result
  # end
end