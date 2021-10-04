# frozen_string_literal: true

# Force httpclient to use the default system cacert configuration.
# Otherwise, when the cacerts bundled with httpclient expire we are
# prone to get validation errors in different places (for example,
# openid_connect gem depends on this, and we were left without login).
# This patch has been copied from the gitlab PR:
# https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30749/diffs.
module HTTPClient::SSLConfigDefaultPaths
  def initialize(client)
    super

    set_default_paths
  end
end

HTTPClient::SSLConfig.prepend HTTPClient::SSLConfigDefaultPaths
