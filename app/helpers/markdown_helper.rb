# frozen_string_literal: true

module MarkdownHelper
  def markdown(text)
    @markdown_renderer ||=
      # see https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
      Redcarpet::Markdown.new(renderer,
                              no_intra_emphasis: true, tables: true,
                              fenced_code_blocks: true,
                              autolink: true, strikethrough: true,
                              lax_html_blocks: true,
                              space_after_headers: true,
                              superscript: true)

    # we can disable cop because Markdown render method ensures its output
    # is html safe.
    #
    # rubocop:disable Rails/OutputSafety
    @markdown_renderer.render(text || "").html_safe
    # rubocop:enable Rails/OutputSafety
  end

  private
    def renderer
      Redcarpet::Render::HTML.new(filter_html: true)
    end
end
