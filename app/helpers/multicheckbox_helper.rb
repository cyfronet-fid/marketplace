# frozen_string_literal: true

module MulticheckboxHelper
  def multi_checkbox(name, value, options)
    if value.nil?
      value = []
    end

    result = "<div class=\"collapse\" data-controller=\"multicheckbox\" id=\"#{name}\">"
    options.each do | option |
      disabled = (option[2] == 0)
      result += "<div data-target=\"multicheckbox.element\"><label
                 data-multicheckbox class=\"#{disabled ? "text-muted" : ""} small\">
                 <input class=\"form-check-input\" #{disabled ? "disabled=\"disabled\"" : ""} name=\"#{name}[]\"
                        multiple=\"true\" type=\"checkbox\" #{value.include?(option[1].to_s) ? "checked=\"checked\"" : ""} value=\"#{option[1]}\">#{option[0]}</label>
                 <span class=\"float-right small #{disabled ? "text-muted" : ""}\">#{option[2]}</span></div>"
    end

    result += "<a data-target=\"multicheckbox.toggler\" href=\"javascript:undefined\"
                  data-action=\"click->multicheckbox#toggle\"></a></div>"
    result.html_safe
  end
end
