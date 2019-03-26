# frozen_string_literal: true

module MulticheckboxHelper
  def multi_checkbox(name, value, options)
    if value.nil?
      value = []
    end

    result = "<div class=\"collapse\" data-controller=\"multicheckbox\" id=\"#{name}\">"

    result += "<div data-target=\"multicheckbox.element\" class=\"checkbox empty\"><label class=\"small\">
                 <input class=\"form-check-input\" name=\"providers[]\" multiple=\"true\" type=\"checkbox\" value=\"9\">
                 <span class=\"cr\"><i class=\"cr-icon fas fa-check\"></i></span>sample empty filter</label>
                 <span class=\"float-right counter\">0</span></div>"

    options.each do | option |
      disabled = (option[2] == 0)
      result += "<div data-target=\"multicheckbox.element\" class=\"checkbox\"><label
                 data-multicheckbox class=\"#{disabled ? "text-muted" : ""} small\">
                 <input class=\"form-check-input\" #{disabled ? "disabled=\"disabled\"" : ""} name=\"#{name}[]\"
                        multiple=\"true\" type=\"checkbox\" #{value.include?(option[1].to_s) ? "checked=\"checked\"" : ""} value=\"#{option[1]}\">
                 <span class=\"cr\"><i class=\"cr-icon fas fa-check\"></i></span>#{option[0]}</label>
                 <span class=\"float-right counter #{disabled ? "text-muted" : ""}\">#{option[2]}</span></div>"
    end

    result += "<a data-target=\"multicheckbox.toggler\" href=\"javascript:undefined\"
                  data-action=\"click->multicheckbox#toggle\"></a></div>"
    result.html_safe
  end
end
