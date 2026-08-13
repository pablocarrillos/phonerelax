# Cifrado de atributos en BD (Active Record Encryption): protege el token de
# VeriFactu si alguien accede a la base de datos o a un backup. Las claves se derivan del secret_key_base (estable en
# producción), así no hay secretos nuevos que repartir. OJO: una copia de la BD
# de producción bajada a local no puede descifrar estos campos (el
# secret_key_base local es otro); basta vaciarlos con update_columns si estorban.
Rails.application.configure do
  key_generator = ActiveSupport::KeyGenerator.new(
    Rails.application.secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA256
  )
  config.active_record.encryption.primary_key = key_generator.generate_key("active_record_encryption/primary", 32).unpack1("H*")
  config.active_record.encryption.deterministic_key = key_generator.generate_key("active_record_encryption/deterministic", 32).unpack1("H*")
  config.active_record.encryption.key_derivation_salt = key_generator.generate_key("active_record_encryption/salt", 32).unpack1("H*")
  # Los valores guardados antes de cifrar siguen leyéndose en claro hasta que se
  # re-cifren (record.encrypt); sin esto, el arranque tras el deploy los rompería.
  config.active_record.encryption.support_unencrypted_data = true
end
