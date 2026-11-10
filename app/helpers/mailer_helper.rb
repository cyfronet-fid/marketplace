# frozen_string_literal: true

module MailerHelper
  BUTTON_COLOR = "#257B85"

  BUTTON_STYLE = [
    "display:inline-block",
    "padding:12px 24px",
    "margin:0 8px 8px 0",
    "border-radius:64px",
    "border:1px solid #{BUTTON_COLOR}",
    "background-color:#{BUTTON_COLOR}",
    "font-family:'Roboto',Arial,Helvetica,sans-serif",
    "font-size:16px",
    "line-height:22px",
    "font-weight:500",
    "color:#ffffff",
    "text-decoration:none"
  ].join("; ").freeze

  def email_font_style
    "font-family:'Roboto',Arial,Helvetica,sans-serif;"
  end

  def email_body_text_style
    "#{email_font_style} font-size:16px; line-height:26px; color:#363939;"
  end

  def email_footer_text_style
    "#{email_font_style} font-size:14px; line-height:22px; color:#363939;"
  end

  def email_table_attributes
    { role: "presentation", cellpadding: 0, cellspacing: 0, border: 0, width: "100%" }
  end

  # EOSC PL pill button: a VML shape for Outlook, an inline-styled link for every other client.
  def email_button(label, href)
    safe_join([outlook_button(label, href), web_button(label, href)])
  end

  private

  def web_button(label, href)
    safe_join(
      [
        "<!--[if !mso]><!-- -->".html_safe,
        link_to(label, href, class: "btn-a", target: "_blank", rel: "noopener", style: BUTTON_STYLE),
        "<!--<![endif]-->".html_safe
      ]
    )
  end

  def outlook_button(label, href)
    width = (label.length * 9) + 50
    <<~VML.html_safe
      <!--[if mso]>
      <v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word"
        href="#{ERB::Util.html_escape(href)}" style="height:46px;v-text-anchor:middle;width:#{width}px;"
        arcsize="50%" strokecolor="#{BUTTON_COLOR}" strokeweight="1px" fillcolor="#{BUTTON_COLOR}">
        <w:anchorlock/>
        <center style="color:#ffffff;font-family:Arial,Helvetica,sans-serif;font-size:16px;font-weight:500;">#{ERB::Util.html_escape(label)}</center>
      </v:roundrect>
      <![endif]-->
    VML
  end
end
