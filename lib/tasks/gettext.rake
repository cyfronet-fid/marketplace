# frozen_string_literal: true

namespace :gettext do
  def files_to_translate
    files = Dir.glob("{app,lib,config,locale}/**/*.{rb,erb,haml,slim}")
    files += Dir.glob("#{ENV["CUSTOMIZATION_PATH"]}/**/*.{rb,erb,haml,slim}") unless ENV["CUSTOMIZATION_PATH"].nil?

    files
  end
end
