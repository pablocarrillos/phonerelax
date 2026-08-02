# Campos con traducción al portugués (columna `<campo>_pt`). `display_<campo>`
# devuelve la versión portuguesa cuando el idioma activo es :pt y hay traducción;
# en caso contrario, el contenido original (español).
module Translatable
  extend ActiveSupport::Concern

  class_methods do
    def translates(*fields)
      fields.each do |field|
        define_method("display_#{field}") do
          translation = public_send("#{field}_pt")
          I18n.locale == :pt && translation.present? ? translation : public_send(field)
        end
      end
    end
  end
end
