# frozen_string_literal: true

require "rails_helper"

describe MarkdownHelper, backend: true do
  it "converts from markdown to html" do
    expect(markdown("# h1")).to match(/<h1>h1/)
  end

  it "produces safe html" do
    expect(markdown("<script>alert('js injected')</script>")).to match(/alert\('js injected'\)/)
  end
end
