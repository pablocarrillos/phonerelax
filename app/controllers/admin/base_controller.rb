module Admin
  # Todo el panel exige sesión iniciada (concern Authentication del ApplicationController).
  class BaseController < ApplicationController
    layout 'admin'
  end
end
