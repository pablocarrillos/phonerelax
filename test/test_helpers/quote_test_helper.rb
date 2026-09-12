# Ayudas para los tests que necesitan presupuestos.
module QuoteTestHelper
  # Las dos imágenes del diseño son OBLIGATORIAS al crear un presupuesto, así
  # que casi todos los tests las necesitan aunque no vayan de eso. Este ayudante
  # se las pone; los tests que prueban precisamente la obligatoriedad usan
  # Quote.create! / el formulario a pelo.
  def create_quote(**attributes)
    Quote.create!(**design_image_params, **attributes)
  end

  # Las dos imágenes, tal cual las manda el formulario del admin.
  def design_image_params
    { case_front_image: fixture_file_upload("cover.png", "image/png"),
      case_back_image: fixture_file_upload("cover.png", "image/png") }
  end
end
