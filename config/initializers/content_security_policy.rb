# Content-Security-Policy en modo report-only: no bloquea nada todavía, pero
# permite ver en la consola del navegador qué habría que ajustar antes de
# activarla en serio (defensa en profundidad frente a XSS).
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data, :https
    policy.object_src  :none
    policy.script_src  :self, :unsafe_inline
    policy.style_src   :self, :unsafe_inline
    policy.frame_src   :self, "https://www.youtube.com", "https://www.youtube-nocookie.com"
    policy.connect_src :self
  end

  config.content_security_policy_report_only = true
end
