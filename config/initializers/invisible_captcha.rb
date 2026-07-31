InvisibleCaptcha.setup do |config|
  # Un humano tarda más de 4 segundos en rellenar los formularios protegidos.
  config.timestamp_threshold = 4.seconds
end
