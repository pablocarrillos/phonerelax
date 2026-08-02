require "test_helper"

class QuoteRequestTest < ActiveSupport::TestCase
  test "requiere nombre, organización, email y mensaje" do
    q = QuoteRequest.new
    assert_not q.valid?
    assert q.errors[:name].any?
    assert q.errors[:organization].any?
    assert q.errors[:email].any?
    assert q.errors[:message].any?
  end

  test "es válido con los campos requeridos" do
    q = QuoteRequest.new(name: "Ana", organization: "IES X", email: "a@x.com",
                         message: "Quiero 100 bolsas para el instituto")
    assert q.valid?
  end

  test "units, si se indica, debe ser un entero positivo" do
    base = { name: "Ana", organization: "IES X", email: "a@x.com", message: "x" }
    assert_not QuoteRequest.new(base.merge(units: 0)).valid?
    assert QuoteRequest.new(base.merge(units: 50)).valid?
    assert QuoteRequest.new(base.merge(units: nil)).valid?
  end
end
