# frozen_string_literal: true

module Verifactu
  # Error transitorio (red o 5xx): el job reintenta solo.
  class TemporaryError < Error; end
end
