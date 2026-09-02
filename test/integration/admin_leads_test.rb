require "test_helper"

# Leads comerciales (copiado de gestion): seguimiento con gestiones cuya
# última entrada fija el estado y el presupuesto, y vínculos con el envío de
# muestras y la generación de presupuestos (al añadir los datos fiscales).
class AdminLeadsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @lead = Lead.create!(name: "Colegio Lead", phone: "600111222", city: "Elda", origin: "web",
                         email_list: "ampa@colegiolead.es, direccion@colegiolead.es")
    @product = Product.create!(name: "Funda lead", price: 12.10, stock: 50, vat_percentage: 21, active: true)
  end

  test "una muestra existente se vincula a un lead desde su formulario y queda en el historial" do
    sample = Sample.create!(organization: "Colegio Suelto", email: "suelto@example.com", sent_on: Date.current)
    sample.sample_lines.create!(product: @product, quantity: 2)

    patch admin_sample_path(sample), params: { sample: { organization: sample.organization, lead_id: @lead.id } }
    assert_redirected_to admin_samples_path

    assert_equal @lead, sample.reload.lead
    @lead.reload
    assert_equal "Muestra enviada", @lead.status
    assert_includes @lead.lead_managements.first.action, "Colegio Suelto"

    # guardar de nuevo sin cambiar el lead no duplica la gestión
    assert_no_difference -> { @lead.lead_managements.count } do
      patch admin_sample_path(sample), params: { sample: { organization: sample.organization, lead_id: @lead.id } }
    end
  end

  test "desde una muestra sin lead se crea un lead vinculado con sus datos" do
    sample = Sample.create!(organization: "Academia Nueva", email: "info@academianueva.es", sent_on: Date.current)
    sample.sample_lines.create!(product: @product, quantity: 3)

    assert_difference -> { Lead.count }, 1 do
      post create_lead_admin_sample_path(sample)
    end
    lead = Lead.order(:id).last
    assert_redirected_to admin_lead_path(lead)
    assert_equal "Academia Nueva", lead.name
    assert_equal [ "info@academianueva.es" ], lead.lead_emails.map(&:email)
    assert_equal lead, sample.reload.lead
    assert_equal "Muestra enviada", lead.status, "el historial arranca con el envío de la muestra"

    # con lead ya vinculado no se crea otro
    assert_no_difference -> { Lead.count } do
      post create_lead_admin_sample_path(sample)
    end
  end

  test "el lead se crea con varios emails y sale en el listado" do
    assert_equal %w[ampa@colegiolead.es direccion@colegiolead.es], @lead.lead_emails.map(&:email).sort
    assert_equal "1er contacto", @lead.status

    get admin_leads_path
    assert_response :success
    assert_includes response.body, "Colegio Lead"

    get admin_leads_path(q: "colegiolead")
    assert_includes response.body, "Colegio Lead"
    get admin_leads_path(q: "no-existe-nada")
    assert_not_includes response.body, "Colegio Lead"
  end

  test "la última gestión fija el estado y el presupuesto del lead" do
    post admin_lead_managements_path(@lead), params: { lead_management: {
      status: "Presupuestado sucio", channel: "Llamada", happened_at: Time.current, budget_amount: "1500",
      action: "Llamada con el director: quieren 200 fundas."
    } }
    assert_redirected_to admin_lead_path(@lead)
    @lead.reload
    assert_equal "Presupuestado sucio", @lead.status
    assert_equal 1500.to_d, @lead.budget_amount

    # borrar la gestión recalcula el estado con lo que quede
    delete admin_lead_management_path(@lead, @lead.lead_managements.first)
    @lead.reload
    assert_nil @lead.budget_amount
    assert_empty @lead.lead_managements
  end

  test "enviar una muestra desde el lead la vincula y queda en su historial" do
    post admin_samples_path, params: { sample: {
      lead_id: @lead.id, organization: @lead.name, sent_on: Date.current.iso8601,
      sample_lines_attributes: { "0" => { product_id: @product.id, quantity: 3 } }
    } }
    assert_redirected_to admin_lead_path(@lead)

    sample = Sample.last
    assert_equal @lead, sample.lead
    @lead.reload
    assert_equal "Muestra enviada", @lead.status, "el envío de muestra actualiza el estado"
    management = @lead.lead_managements.first
    assert_equal "Muestra", management.channel
    assert_includes management.action, "3× Funda lead"
  end

  test "al añadir datos fiscales se crea el cliente vinculado y el presupuesto queda en el historial" do
    # paso 1: datos fiscales → cliente vinculado y salto a generar presupuesto
    post admin_clients_path, params: { lead_id: @lead.id, client: {
      name: "Colegio Lead SL", tax_id: "B12345678", address: "C/ Mayor 1", email: "ampa@colegiolead.es"
    } }
    client = Client.last
    assert_redirected_to new_admin_quote_path(client_id: client.id, lead_id: @lead.id)
    assert_equal client, @lead.reload.client

    # paso 2: el formulario de presupuesto llega con cliente y lead vinculados
    get new_admin_quote_path(client_id: client.id, lead_id: @lead.id)
    assert_response :success
    assert_includes response.body, "vinculado al lead"

    # paso 3: crear el presupuesto lo vincula y actualiza el lead con su importe
    post admin_quotes_path, params: { quote: {
      client_id: client.id, lead_id: @lead.id, issued_on: Date.current.iso8601, delivery_terms: "2 semanas",
      shipping_cost: 0, vat_rate: 21,
      quote_lines_attributes: { "0" => { description: "Fundas personalizadas", quantity: 100, unit_price: "9", vat_rate: 21 } }
    } }
    quote = Quote.last
    assert_redirected_to admin_quote_path(quote)
    assert_equal @lead, quote.lead

    @lead.reload
    assert_equal "Presupuestado formal", @lead.status
    assert_equal quote.total, @lead.budget_amount, "el presupuesto del lead es el total del presupuesto generado"
    management = @lead.lead_managements.first
    assert_equal "Presupuesto", management.channel
    assert_includes management.action, quote.number

    # y la ficha del lead enseña ambos vínculos
    get admin_lead_path(@lead)
    assert_response :success
    assert_includes response.body, quote.number
    assert_includes response.body, "Colegio Lead SL"
  end

  test "un lead perdido deja de estar a contestar y cae en su sección" do
    @lead.update!(to_answer: true)
    post admin_lead_managements_path(@lead), params: { lead_management: {
      status: "Perdido", channel: "Correo", happened_at: Time.current, action: "No siguen adelante."
    } }
    @lead.reload
    assert_equal "Perdido", @lead.status
    @lead.update!(to_answer: true) # el modelo lo apaga solo al validar
    assert_not @lead.reload.to_answer?

    get admin_leads_path(section: "lost")
    assert_includes response.body, "Colegio Lead"
    get admin_leads_path
    assert_not_includes response.body, "Colegio Lead"
  end
end
