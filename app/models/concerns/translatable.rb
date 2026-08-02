# Campos con traducción por idioma (columnas `<campo>_<locale>`, p. ej. name_pt,
# name_en). `display_<campo>` devuelve la traducción del idioma activo cuando
# existe; si falta (o es el idioma por defecto), devuelve el contenido original
# en español.
module Translatable
  extend ActiveSupport::Concern

  class_methods do
    def translates(*fields)
      fields.each do |field|
        define_method("display_#{field}") do
          if I18n.locale != I18n.default_locale
            column = "#{field}_#{I18n.locale}"
            translation = respond_to?(column) ? public_send(column) : nil
            return translation if translation.present?
          end
          public_send(field)
        end
      end
    end
  end
end
