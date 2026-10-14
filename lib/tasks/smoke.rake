# frozen_string_literal: true

require "net/http"
require "uri"
require "cgi"
require "nokogiri"

# Two checks of a locally running marketplace, over HTTP, without the Rails
# environment:
#
#   rake "smoke:crawl[<base-url>,<cookie-jar>]"   every page answers 2xx/3xx (Smoke::Crawler)
#   rake "smoke:forms[<base-url>,<cookie-jar>]"   the backoffice forms render and submit (Smoke::Forms)
#
# The cookie jar is a curl/Netscape cookie file (curl -c <file>);
# lib/versions/smoke_test.sh and lib/versions/check_forms.sh log in through the
# auth mock and write it.
#
# smoke:crawl reports every page that does not answer 2xx/3xx. Only GET
# requests are sent; links that Turbo or rails-ujs would send as
# DELETE/POST/PATCH (data-turbo-method, data-method) are skipped, so the crawl
# does not change any data.
#
#   rake "smoke:crawl[http://localhost:5000]"
#     crawls as an anonymous visitor, starting from "/"
#   rake "smoke:crawl[http://localhost:5000,${TMPDIR:-/tmp}/mp_smoke_cookies_localhost_5000.txt]"
#     crawls as the logged-in user; also starts from /backoffice, /admin,
#     /projects and /profile
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
  # What both tasks share: the session of a cookie jar, the URL shapes that
  # count as one page and the message of the Rails error page.
  module Site
    SKIP = %r{
      \A/(users|assets|rails|packs|api_docs|api/|admin/jobs|admin/sidekiq|letter_opener)
      |sign_out|logout|\.(png|jpg|svg|pdf|ico|json|xml|csv)\z
    }x
    ID_PARENTS = %w[services providers datasources catalogues bundles offers projects categories research_products
                    deployable_services scientific_domains platforms vocabularies target_users].freeze

    module_function

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

    def build_http(base)
      http = Net::HTTP.new(base.host, base.port)
      http.use_ssl = base.scheme == "https"
      http.read_timeout = 120
      http
    end

    # The hrefs of the <a> tags of a page, query strings kept; links that
    # rails-ujs or Turbo would send with another method are left out.
    def links(body)
      body.scan(/<a\b[^>]*>/).filter_map do |tag|
        next if tag.match?(/data-(turbo-)?method=/)

        href = tag[%r{href=["'](/[^"'#]*)["']}, 1]
        href && CGI.unescapeHTML(href)
      end
    end
  end

  class Crawler
    PER_SHAPE = 2

    def initialize(base_url, cookie_jar = nil, max_pages: ENV.fetch("MAX_PAGES", 500).to_i,
                   verbose: ENV.fetch("VERBOSE", nil))
      @base = URI(base_url)
      @cookie = Site.read_cookie(cookie_jar)
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

    def crawl
      queue = ["/"]
      queue << "/backoffice" << "/admin" << "/projects" << "/profile" if @cookie
      state = { queue: queue, seen: Set.new(queue), shapes: Hash.new(0), results: [] }

      http = Site.build_http(@base)
      while (path = queue.shift) && state[:results].size < @max_pages
        request_page(http, path, state)
      end

      state[:results]
    end

    def request_page(http, path, state)
      req = Net::HTTP::Get.new(path)
      req["Cookie"] = @cookie if @cookie
      req["Accept"] = "text/html"
      res = http.request(req)
      state[:results] << [res.code.to_i, path, res.code == "500" ? Site.exception_message(res.body.to_s) : nil]
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
      state[:queue] << target if !target.match?(Site::SKIP) && state[:seen].add?(target)
    end

    def enqueue_links(body, state)
      Site.links(body).each do |href|
        target = href.split("?").first
        next if target.match?(Site::SKIP) || !state[:seen].add?(target)
        next if (state[:shapes][Site.shape(target)] += 1) > PER_SHAPE

        state[:queue] << target
      end
    end
  end

  # Exercises the backoffice forms as the logged-in user of the cookie jar:
  #
  #   1. Crawls the backoffice (GET only, as smoke:crawl does) and collects the
  #      form pages: /new, /edit (also edit?step=...), and the provider tabs
  #      (?tab=..., requested as turbo streams, the way the page requests them).
  #   2. Requests every form page and parses the forms on it.
  #   3. Submits each form back with the values it contains. An edit form
  #      re-saves the record unchanged, so a 422 means the form and the model
  #      disagree (a field the policy does not permit, a value the form does
  #      not render) and a 500 is a broken controller or view. A form on a
  #      /new page is submitted empty and is expected to answer 422.
  #   4. Walks the provider wizard of one provider from its first step to
  #      Finish, re-saving the values of each step.
  #
  # Forms that change the state of a record (publish, unpublish, draft,
  # suspend, delete, the approval decision, button_to forms) are never
  # submitted.
  #
  #   SUBMIT=edit (default)  submit the edit forms and the wizard, only GET the /new pages
  #   SUBMIT=all             also submit the /new forms empty (a 422 is the expected answer)
  #   SUBMIT=none            only GET the form pages
  #   SAMPLE=<n>             records per resource (default 2)
  #   MAX_PAGES=<n>          pages crawled to find the forms (default 400)
  #
  # A re-saved record gets a new updated_at and runs its callbacks (search
  # index, JMS), so run this against a local variant environment
  # (lib/versions/run_variant_env.sh) or accept that on a test deployment.
  # For a deployment without the auth mock, put the session cookie of a
  # logged-in browser into the jar.
  #
  # Output: one line per request (status, method, path, note), the counts per
  # status, then the failures. For a 500 the note is the exception message of
  # the Rails error page, for a 4xx the validation messages of the form. The
  # exit status is 1 when a form page or a submission failed; the 422 of an
  # empty /new form is expected, not a failure.
  class Forms
    FORM_PAGE = %r{/(new|edit)\z}
    STATE_CHANGING = %r{/(publish|unpublish|draft|suspend|exit|statuses|approval_requests|summary)(/|\z)}
    FORWARD_BUTTON = /\A(next|finish)\b/i
    SUBMIT_BUTTON = /\A(update|save|submit|create)\b(?!.*draft)/i
    TURBO_STREAM = "text/vnd.turbo-stream.html, text/html;q=0.9"
    ERROR_SELECTORS = ".invalid-feedback, .alert-danger, .error_notification, #error_explanation li, .text-danger"
    SEEDS = %w[/backoffice /backoffice/services /backoffice/providers /backoffice/catalogues].freeze

    Result = Struct.new(:status, :verb, :path, :note, :expected) do
      def failed?
        status >= 400 && !expected
      end

      def to_s
        [status, verb.ljust(5), path, note].compact.join("  ")
      end
    end

    def initialize(base_url, cookie_jar, submit: ENV.fetch("SUBMIT", "edit"), sample: ENV.fetch("SAMPLE", 2).to_i,
                   max_pages: ENV.fetch("MAX_PAGES", 400).to_i)
      @base = URI(base_url)
      @cookie = Site.read_cookie(cookie_jar)
      @submit = submit
      @sample = sample
      @max_pages = max_pages
      @http = Site.build_http(@base)
      @results = []
    end

    # Returns true when every form page rendered and every submission was accepted.
    def call
      return puts("no session cookie; log in first (lib/versions/check_forms.sh)") || false unless @cookie

      pages = discover_form_pages
      puts "form pages: #{pages.size} (SUBMIT=#{@submit})"
      pages.each { |path, accept| check_page(path, accept) }
      walk_wizard(pages) unless @submit == "none"
      report
    end

    private

    # Crawls the backoffice and returns the [path, accept] pairs of the form
    # pages, at most SAMPLE per URL shape (a tab or step counts as its own shape).
    def discover_form_pages
      state = { queue: SEEDS.dup, seen: Set.new(SEEDS), shapes: Hash.new(0), pages: {} }
      visited = 0
      while (path = state[:queue].shift) && visited < @max_pages
        visited += 1
        res = get(path, "text/html")
        next unless res.code == "200" && res["content-type"].to_s.include?("html")

        Site.links(res.body).each { |href| collect_link(href, state) }
      end
      state[:pages].to_a
    end

    def collect_link(href, state)
      path, query = href.split("?", 2)
      return unless path.start_with?("/backoffice") && !path.match?(Site::SKIP)

      if form_page?(path, query)
        key = "#{shape(path)}?#{query.to_s[/(step|tab)=[^&]*/]}"
        if (state[:shapes][key] += 1) <= @sample
          state[:pages][href] =
            query.to_s.include?("tab=") ? TURBO_STREAM : "text/html"
        end
      end
      return if query || !state[:seen].add?(path) || (state[:shapes][shape(path)] += 1) > @sample

      state[:queue] << path
    end

    # As Site.shape, but each vocabulary type (vocabularies/trls, /nodes, ...)
    # is its own shape, so every type's listing and forms are visited.
    def shape(path)
      type = path[%r{/vocabularies/([a-z_]+)}, 1]
      type ? "#{Site.shape(path.sub("/vocabularies/#{type}", "/vocabularies"))}##{type}" : Site.shape(path)
    end

    def form_page?(path, query)
      path.match?(FORM_PAGE) || query.to_s.match?(/(\A|&)tab=/)
    end

    def check_page(path, accept)
      res = record(get(path, accept), "GET", path)
      return unless res.code == "200"

      new_form = path.end_with?("/new")
      return if @submit == "none" || (new_form && @submit != "all")

      forms(res.body).each do |form|
        action = form["action"].to_s
        next if skip_form?(form, action)

        submit(form, action, expect_invalid: new_form)
      end
    end

    def skip_form?(form, action)
      verb = verb_of(form)
      verb == "GET" || verb == "DELETE" || form["class"].to_s.include?("button_to") ||
        !action.start_with?("/backoffice") || action.match?(STATE_CHANGING)
    end

    # The provider wizard: the edit of the first step enters it; every step is
    # submitted with its values and "Next" until "Finish" saves the provider
    # and redirects. With SUBMIT=all the wizard of a new provider is entered
    # too and its empty first step submitted.
    def walk_wizard(pages)
      provider = pages.map(&:first).filter_map { |p| p[%r{\A/backoffice/providers/[^/?]+(?=/edit)}] }.first
      if provider
        res = record(get("#{provider}/edit?step=profile", "text/html"), "GET", "#{provider}/edit?step=profile")
        walk_steps("#{provider}/wizard") if res.is_a?(Net::HTTPRedirection)
      else
        puts "wizard: no provider edit page found"
      end
      return unless @submit == "all"

      record(get("/backoffice/providers/new", "text/html"), "GET", "/backoffice/providers/new")
      walk_steps("/backoffice/providers/new/wizard", limit: 1, expect_invalid: true)
    end

    def walk_steps(wizard, limit: 10, expect_invalid: false)
      limit.times do
        res = record(get(wizard, "text/html"), "GET", wizard)
        break unless res.code == "200"

        form = forms(res.body).find { |f| f["action"].to_s.end_with?("/wizard") }
        break puts("wizard: no form on #{wizard}") unless form

        res = submit(form, form["action"], expect_invalid: expect_invalid)
        break if res.code.to_i >= 400 || res.is_a?(Net::HTTPRedirection)
      end
    end

    # expect_invalid: the form was submitted empty, so a 422 is the expected answer.
    def submit(form, action, expect_invalid: false)
      req = Net::HTTP::Post.new(action)
      req["Cookie"] = @cookie
      req["Accept"] = TURBO_STREAM
      req.set_form_data(form_params(form))
      res = @http.request(req)
      note = res.code.to_i >= 400 && res.code != "500" ? validation_errors(res.body.to_s) : nil
      record(res, verb_of(form), action, note, expected: expect_invalid && res.code == "422")
    end

    # The fields a browser would send: hidden, text and checked inputs, the
    # selected options, the textareas and the submit button of the form.
    def form_params(form)
      params = form.css("input, select, textarea").flat_map { |field| field_params(field) }
      params + commit_param(form)
    end

    def field_params(field)
      name = field["name"].to_s
      return [] if name.empty? || field.key?("disabled")

      case field.name
      when "input" then input_params(field, name)
      when "textarea" then [[name, field.text.sub(/\A\n/, "")]]
      when "select" then selected_options(field).map { |o| [name, o["value"] || o.text] }
      else []
      end
    end

    def input_params(field, name)
      type = field["type"].to_s.downcase
      return [] if %w[file submit button image reset].include?(type)
      return [] if %w[checkbox radio].include?(type) && !field.key?("checked")

      [[name, field["value"].to_s]]
    end

    def selected_options(select)
      selected = select.css("option[selected]")
      selected = select.css("option").first(1) if selected.empty? && !select.key?("multiple")
      selected
    end

    # The button a user would press to save: Next or Finish in the wizard,
    # otherwise Update/Save/Create (not "Save as draft"), otherwise the first one.
    def commit_param(form)
      buttons = form.css("input[type=submit][name], button[type=submit][name], button[name]:not([type])")
      button = buttons.find { |b| b["value"].to_s.match?(FORWARD_BUTTON) } ||
               buttons.find { |b| b["value"].to_s.match?(SUBMIT_BUTTON) } || buttons.first
      button ? [[button["name"], button["value"].to_s]] : []
    end

    def verb_of(form)
      (form.at_css("input[name=_method]")&.[]("value") || form["method"] || "post").upcase
    end

    def forms(body)
      document(body).css("form")
    end

    # Turbo streams wrap their HTML in <template>; the tags are dropped so
    # the parser sees the forms inside.
    def document(body)
      Nokogiri::HTML(body.gsub(%r{</?template[^>]*>}, ""))
    end

    # The validation messages of the page, each with the label of its field
    # ("Abbreviation: can't be blank"); the general notice only when there is
    # nothing more specific.
    def validation_errors(body)
      doc = document(body)
      messages = doc.css(".invalid-feedback, #error_explanation li, .text-danger").filter_map { |n| field_message(n) }
      messages = doc.css(".alert-danger, .error_notification").map { |n| squeeze(n.text) } if messages.empty?
      messages.empty? ? nil : messages.uniq.first(4).join(" | ")[0, 240]
    end

    def field_message(node)
      text = squeeze(node.text)
      return if text.empty?

      label = node.parent&.at_css("label")
      label ? "#{squeeze(label.text).delete_suffix("*").strip}: #{text}" : text
    end

    def squeeze(text)
      text.squeeze(" \n").strip
    end

    def get(path, accept)
      req = Net::HTTP::Get.new(path)
      req["Cookie"] = @cookie
      req["Accept"] = accept
      @http.request(req)
    end

    def record(res, verb, path, note = nil, expected: false)
      note ||= Site.exception_message(res.body.to_s) if res.code == "500"
      result = Result.new(res.code.to_i, verb, path, note, expected)
      @results << result
      puts result
      res
    end

    def report
      puts
      @results.group_by(&:status).sort.each { |status, rows| puts "#{status}: #{rows.size}" }
      failed = @results.select(&:failed?)
      puts "--- failed: #{"none" if failed.empty?}"
      failed.each { |result| puts result }
      failed.empty?
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

  desc "Render and re-submit the backoffice forms of a running marketplace (args: base_url, cookie_jar)"
  task :forms, %i[base_url cookie_jar] do |_, args| # rubocop:disable Rails/RakeEnvironment
    if args.base_url.to_s.empty? || args.cookie_jar.to_s.empty?
      abort 'usage: rake "smoke:forms[<base-url>,<cookie-jar>]" (lib/versions/check_forms.sh logs in and runs it)'
    end

    ok = Smoke::Forms.new(args.base_url, args.cookie_jar).call
    exit(ok ? 0 : 1)
  end
end
