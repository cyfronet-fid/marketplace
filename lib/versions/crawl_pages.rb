# frozen_string_literal: true

# Crawls a locally running marketplace and reports every page that does not
# answer 2xx/3xx. Only GET requests are sent; links that Turbo or rails-ujs
# would send as DELETE/POST/PATCH (data-turbo-method, data-method) are skipped,
# so the crawl does not change any data.
#
# Usage:
#   ruby crawl_pages.rb <base-url> [cookie-jar]
#
#   ruby crawl_pages.rb http://localhost:5000
#     crawls as an anonymous visitor, starting from "/"
#
#   ./smoke_test.sh                                    # logs in, writes the cookie jar
#   ruby crawl_pages.rb http://localhost:5000 "${TMPDIR:-/tmp}/mp_smoke_cookies_5000.txt"
#     crawls as the logged-in user; also starts from /backoffice, /admin,
#     /projects and /profile
#
# The cookie jar is a curl/Netscape cookie file (curl -c <file>).
#
# How far it goes:
#   - links are taken from href="/..." of every 200 HTML page, query strings dropped
#   - at most PER_SHAPE pages per URL shape, where a numeric segment and the
#     segment after a resource name (services, providers, ...) count as :id,
#     so /services/a and /services/b are one shape
#   - at most MAX_PAGES pages in total (default 500, MAX_PAGES=2000 ruby crawl_pages.rb ...)
#   - SKIP lists what is never requested (login/logout, assets, api docs, files)
#
# Output: number of pages per status code, then every 4xx/5xx path. For a 500
# in development the exception message of the Rails error page is printed next
# to the path; the backtrace is in log/development.log of the application.
# VERBOSE=1 prints every requested page with its status while crawling.
require "net/http"
require "uri"
require "cgi"

MAX_PAGES = ENV.fetch("MAX_PAGES", 500).to_i
PER_SHAPE = 2
SKIP = %r{\A/(users|assets|rails|packs|api_docs|api/|admin/jobs|admin/sidekiq|letter_opener)|sign_out|logout|\.(png|jpg|svg|pdf|ico|json|xml|csv)\z}
ID_PARENTS = %w[services providers datasources catalogues bundles offers projects categories research_products
                deployable_services scientific_domains platforms vocabularies target_users].freeze

abort "usage: ruby crawl_pages.rb <base-url> [cookie-jar]" if ARGV.empty?

base = URI(ARGV[0])
jar = ARGV[1]
cookie =
  if jar && File.exist?(jar)
    File
      .readlines(jar)
      .reject { |l| l.start_with?("# ") || l.strip.empty? }
      .map { |l| l.sub(/^#HttpOnly_/, "").split("\t") }
      .select { |f| f.size >= 7 }
      .map { |f| "#{f[5]}=#{f[6].strip}" }
      .join("; ")
  end

def shape(path)
  segments = path.split("/")
  segments
    .each_with_index
    .map { |s, i| s.match?(/\A\d+\z/) || (i.positive? && ID_PARENTS.include?(segments[i - 1]) && s != "new") ? ":id" : s }
    .join("/")
end

# The message of the Rails development error page (template errors put it in
# <pre><code>, other exceptions in <div class="message">).
def exception_message(body)
  message = body[%r{<div class="message">(.*?)</div>}m, 1] || body[%r{<pre><code>(.*?)</code></pre>}m, 1]
  message && CGI.unescapeHTML(message.gsub(/<[^>]+>/, " ").squeeze(" ").strip)[0, 200]
end

queue = ["/"]
queue << "/backoffice" << "/admin" << "/projects" << "/profile" if cookie
seen = Set.new(queue)
shapes = Hash.new(0)
results = []

http = Net::HTTP.new(base.host, base.port)
http.use_ssl = base.scheme == "https"
http.read_timeout = 120

while (path = queue.shift) && results.size < MAX_PAGES
  req = Net::HTTP::Get.new(path)
  req["Cookie"] = cookie if cookie
  req["Accept"] = "text/html"
  res = http.request(req)
  results << [res.code.to_i, path, res.code == "500" ? exception_message(res.body.to_s) : nil]
  puts "#{res.code} #{path}" if ENV["VERBOSE"]
  if res.is_a?(Net::HTTPRedirection)
    loc = URI.join(base.to_s, res["location"])
    next unless loc.host == base.host && loc.port == base.port

    target = loc.path
    queue << target if !target.match?(SKIP) && seen.add?(target)
    next
  end
  next unless res.code == "200" && res["content-type"].to_s.include?("html")

  res.body.scan(/<a\b[^>]*>/).each do |tag|
    next if tag.match?(/data-(turbo-)?method=/)

    href = tag[%r{href=["'](/[^"'#]*)["']}, 1]
    target = href&.split("?")&.first
    next if target.nil? || target.match?(SKIP) || !seen.add?(target)
    next if (shapes[shape(target)] += 1) > PER_SHAPE

    queue << target
  end
end

puts "crawled: #{results.size}#{" (stopped at MAX_PAGES)" if results.size >= MAX_PAGES}"
results.group_by(&:first).sort.each { |code, rows| puts "#{code}: #{rows.size}" }
failed = results.reject { |code, _, _| code < 400 }
puts "--- not 2xx/3xx: #{"none" if failed.empty?}"
failed.each { |code, path, message| puts [code, path, message].compact.join("  ") }
exit(failed.empty? ? 0 : 1)
