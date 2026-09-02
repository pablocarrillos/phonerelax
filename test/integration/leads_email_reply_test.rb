require "test_helper"

# Respuestas estándar a leads desde Gmail (copiado de gestion): apellidos y
# asunto en el lead, plantillas con variables, enlace que abre la redacción de
# Gmail con todo relleno y botón «✓ Enviada» que lo apunta en el historial.
class LeadsEmailReplyTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @lead = Lead.create!(name: "María", last_name: "García", city: "Elda", status: Lead::STATUSES.first,
                         to_answer: true, email_list: "maria@example.com", email_subject: "Fundas colegio")
    @template = EmailTemplate.create!(name: "Info general", body: "Hola {nombre} {apellidos}:\nGracias por tu interés.")
  end

  test "el lead guarda apellidos y asunto desde el formulario" do
    patch admin_lead_path(@lead), params: { lead: { name: "María", last_name: "García López", email_subject: "Otro asunto" } }
    assert_redirected_to admin_lead_path(@lead)

    @lead.reload
    assert_equal "María García López", @lead.full_name
    assert_equal "Otro asunto", @lead.email_subject
  end

  test "la ficha enlaza a Gmail con la respuesta cargada, sin prefijo en el asunto" do
    get admin_lead_path(@lead)
    assert_response :success

    hrefs = css_select("a").map { |a| a["href"] }.select { |h| h.to_s.include?("view=cm") }
    assert_equal 1, hrefs.size, "hay un enlace de redactar por plantilla"
    href = hrefs.first
    assert_includes href, "to=maria%40example.com"
    assert_includes href, "su=Fundas+colegio", "responde con el asunto guardado, sin «Re:»"
    assert_includes href, "body=Hola+Mar", "el cuerpo va con las variables sustituidas"
    assert_includes href, "Garc%C3%ADa", "los apellidos también se sustituyen"
    assert_includes href, "authuser=", "abre la cuenta de Gmail del usuario"
  end

  test "marcar la plantilla como enviada la apunta en el historial del lead" do
    post mark_template_sent_admin_lead_path(@lead, template_id: @template.id)
    assert_redirected_to admin_lead_path(@lead)

    management = @lead.lead_managements.reload.first
    assert_equal "Correo", management.channel
    assert_equal @lead.status, management.status, "no cambia el estado del lead"
    assert_includes management.action, "«Info general»"

    get admin_lead_path(@lead)
    assert_includes response.body, "Enviada la plantilla «Info general» por email."
  end

  test "la lista ofrece responder con plantilla y encuentra por apellidos" do
    get admin_leads_path
    assert_response :success
    assert_includes response.body, "Responder con plantilla"
    assert_includes response.body, "view=cm"
    assert_includes response.body, "María García"

    get admin_leads_path(q: "garcía")
    assert_includes response.body, "María García"
  end

  test "las plantillas tienen su CRUD y el listado resalta las variables" do
    post admin_email_templates_path, params: { email_template: { name: "Tarifas", subject: "Tarifas para {ciudad}", body: "Cuerpo {nombre}" } }
    assert_redirected_to admin_email_templates_path
    template = EmailTemplate.find_by(name: "Tarifas")
    assert template

    get admin_email_templates_path
    assert_response :success
    assert_includes response.body, "{nombre}</span>", "las variables van resaltadas"

    patch admin_email_template_path(template), params: { email_template: { body: "Cuerpo nuevo" } }
    assert_equal "Cuerpo nuevo", template.reload.body

    delete admin_email_template_path(template)
    assert_not EmailTemplate.exists?(template.id)
  end
end
