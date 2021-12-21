# frozen_string_literal: true

module MarkdownHelper
  def markdown(text)
    @markdown_renderer ||=
      # see https://github.com/vmg/redcarpet#and-its-like-really-simple-to-use
      Redcarpet::Markdown.new(
        renderer,
        no_intra_emphasis: true,
        tables: true,
        fenced_code_blocks: true,
        filter_html: false,
        autolink: true,
        strikethrough: true,
        lax_html_blocks: true,
        space_after_headers: true,
        superscript: true
      )

    # We do sanitization as the markdown can be a mix of HTML and Markdown and redcarpet itself does not do
    # proper sanitization
    sanitize(@markdown_renderer.render(text || ""))
  end

  private

  def renderer
    Redcarpet::Render::HTML.new(filter_html: false)
  end
end
