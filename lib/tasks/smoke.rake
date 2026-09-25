# frozen_string_literal: true

require "net/http"
require "uri"
require "cgi"

# Crawls a locally running marketplace and reports every page that does not
# answer 2xx/3xx. Only GET requests are sent; links that Turbo or rails-ujs
# would send as DELETE/POST/PATCH (data-turbo-method, data-method) are skipped,
# so the crawl does not change any data.
#
# Usage:
#   rake "smoke:crawl[<base-url>]"
#   rake "smoke:crawl[<base-url>,<cookie-jar>]"
#
#   rake "smoke:crawl[http://localhost:5000]"
#     crawls as an anonymous visitor, starting from "/"
#
#   lib/versions/smoke_test.sh                        # logs in, writes the cookie jar
#   rake "smoke:crawl[http://localhost:5000,${TMPDIR:-/tmp}/mp_smoke_cookies_5000.txt]"
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
#   - at most MAX_PAGES pages in total (default 500, MAX_PAGES=2000 rake "smoke:crawl[...]")
#   - SKIP lists what is never requested (login/logout, assets, api docs, files)
#
# Output: number of pages per status code, then every 4xx/5xx path. For a 500
# in development the exception message of the Rails error page is printed next
# to the path; the backtrace is in log/development.log of the application.
# VERBOSE=1 prints every requested page with its status while crawling.
module Smoke
  class Crawler
    PER_SHAPE = 2
    SKIP = %r{
      \A/(users|assets|rails|packs|api_docs|api/|admin/jobs|admin/sidekiq|letter_opener)
      |sign_out|logout|\.(png|jpg|svg|pdf|ico|json|xml|csv)\z
    }x
    ID_PARENTS = %w[services providers datasources catalogues bundles offers projects categories research_products
                    deployable_services scientific_domains platforms vocabularies target_users].freeze

    def initialize(base_url, cookie_jar = nil, max_pages: ENV.fetch("MAX_PAGES", 500).to_i,
                   verbose: ENV.fetch("VERBOSE", nil))
      @base = URI(base_url)
      @cookie = read_cookie(cookie_jar)
      @max_pages = max_pages
      @verbose = verbose
    end

    # Crawls the site and prints the report. Returns true when every page
    # answered 2xx/3xx, false otherwise.
    def call
      results = crawl

      puts "crawled: #{results.size}#{" (stopped at MAX_PAGES)" if results.size >= @max_pages}"
      results.group_by(&:first).sort.each { |code, rows| puts "#{code}: #{rows.size}" }
      failed = results.reject { |code, _, _| code < 400 }
      puts "--- not 2xx/3xx: #{"none" if failed.empty?}"
      failed.each { |code, path, message| puts [code, path, message].compact.join("  ") }

      failed.empty?
    end

    private

    def read_cookie(jar)
      return unless jar && File.exist?(jar)

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
        .map do |s, i|
          if s.match?(/\A\d+\z/) || (i.positive? && ID_PARENTS.include?(segments[i - 1]) && s != "new")
            ":id"
          else
            s
          end
        end
        .join("/")
    end

    # The message of the Rails development error page (template errors put it in
    # <pre><code>, other exceptions in <div class="message">).
    def exception_message(body)
      message = body[%r{<div class="message">(.*?)</div>}m, 1] || body[%r{<pre><code>(.*?)</code></pre>}m, 1]
      message && CGI.unescapeHTML(message.gsub(/<[^>]+>/, " ").squeeze(" ").strip)[0, 200]
    end

    def crawl
      queue = ["/"]
      queue << "/backoffice" << "/admin" << "/projects" << "/profile" if @cookie
      state = { queue: queue, seen: Set.new(queue), shapes: Hash.new(0), results: [] }

      http = build_http
      while (path = queue.shift) && state[:results].size < @max_pages
        request_page(http, path, state)
      end

      state[:results]
    end

    def build_http
      http = Net::HTTP.new(@base.host, @base.port)
      http.use_ssl = @base.scheme == "https"
      http.read_timeout = 120
      http
    end

    def request_page(http, path, state)
      req = Net::HTTP::Get.new(path)
      req["Cookie"] = @cookie if @cookie
      req["Accept"] = "text/html"
      res = http.request(req)
      state[:results] << [res.code.to_i, path, res.code == "500" ? exception_message(res.body.to_s) : nil]
      puts "#{res.code} #{path}" if @verbose

      if res.is_a?(Net::HTTPRedirection)
        enqueue_redirect(res, state)
      elsif res.code == "200" && res["content-type"].to_s.include?("html")
        enqueue_links(res.body, state)
      end
    end

    def enqueue_redirect(res, state)
      loc = URI.join(@base.to_s, res["location"])
      return unless loc.host == @base.host && loc.port == @base.port

      target = loc.path
      state[:queue] << target if !target.match?(SKIP) && state[:seen].add?(target)
    end

    def enqueue_links(body, state)
      body.scan(/<a\b[^>]*>/).each do |tag|
        next if tag.match?(/data-(turbo-)?method=/)

        href = tag[%r{href=["'](/[^"'#]*)["']}, 1]
        target = href&.split("?")&.first
        next if target.nil? || target.match?(SKIP) || !state[:seen].add?(target)
        next if (state[:shapes][shape(target)] += 1) > PER_SHAPE

        state[:queue] << target
      end
    end
  end
end

namespace :smoke do
  desc "Crawl a running marketplace and report pages that do not answer 2xx/3xx (args: base_url, cookie_jar)"
  # This talks to an already-running server over HTTP; it does not need the Rails environment.
  task :crawl, %i[base_url cookie_jar] do |_, args| # rubocop:disable Rails/RakeEnvironment
    abort 'usage: rake "smoke:crawl[<base-url>,<cookie-jar>]"' if args.base_url.to_s.empty?

    ok = Smoke::Crawler.new(args.base_url, args.cookie_jar).call
    exit(ok ? 0 : 1)
  end
end
