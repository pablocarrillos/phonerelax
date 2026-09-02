# Plantilla de respuesta estándar para contestar a un lead desde Gmail: el
# botón «Responder» abre la ventana de redactar (URL view=cm) con
# destinatario, asunto y cuerpo ya rellenos. Variables disponibles en asunto y
# cuerpo: {nombre}, {apellidos} y {ciudad} del lead. La firma no la pone la
# app: se inserta en Gmail (icono de la pluma) o se escribe en la plantilla.
class EmailTemplate < ApplicationRecord
  PLACEHOLDERS = %w[{nombre} {apellidos} {ciudad}].freeze

  validates :name, presence: true, uniqueness: true
  validates :body, presence: true

  scope :ordered, -> { order(:name) }

  # Cuerpo con las variables del lead sustituidas.
  def body_for(lead)
    fill_in(body, lead)
  end

  # Asunto final: si el lead tiene guardado el asunto de su correo, se usa tal
  # cual (sin prefijo «Re:», que en la práctica abría conversación nueva); si
  # no, el asunto propio de la plantilla.
  def subject_for(lead)
    return lead.email_subject if lead.email_subject.present?

    fill_in(subject.to_s, lead)
  end

  private

  def fill_in(text, lead)
    replacements = { "nombre" => lead.name.to_s, "apellidos" => lead.last_name.to_s, "ciudad" => lead.city.to_s }
    text.gsub(/\{(nombre|apellidos|ciudad)\}/) { replacements[Regexp.last_match(1)] }
  end
end
