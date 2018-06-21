# frozen_string_literal: true

require "rails_helper"

describe MarkdownHelper do
  it "converts from markdown to html" do
    expect(markdown("# h1")).to match(/<h1>h1/)
  end

  it "produces safe html" do
    expect(markdown("<script>alert('js injected')</script>")).
      to match(/<p>alert/)
  end
end
