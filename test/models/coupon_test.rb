require "test_helper"

class CouponTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "el código se normaliza y es único sin distinguir mayúsculas" do
    Coupon.create!(code: " verano26 ", discount_percent: 10)
    assert_equal "VERANO26", Coupon.last.code
    dup = Coupon.new(code: "Verano26", discount_percent: 5)
    assert_not dup.valid?
  end

  test "exige exactamente un tipo de descuento" do
    assert_not Coupon.new(code: "X").valid?
    assert_not Coupon.new(code: "X", discount_percent: 10, discount_amount: 5).valid?
    assert Coupon.new(code: "X", discount_percent: 10).valid?
    assert Coupon.new(code: "Y", discount_amount: 5).valid?
  end

  test "redeemable? respeta habilitado, fechas y usos" do
    coupon = Coupon.create!(code: "A", discount_percent: 10)
    assert coupon.redeemable?

    coupon.update!(enabled: false)
    assert_equal :disabled, coupon.rejection_reason

    coupon.update!(enabled: true, starts_on: Date.tomorrow)
    assert_equal :not_started, coupon.rejection_reason

    coupon.update!(starts_on: nil, ends_on: Date.yesterday)
    assert_equal :expired, coupon.rejection_reason

    coupon.update!(ends_on: nil, max_uses: 2, uses_count: 2)
    assert_equal :exhausted, coupon.rejection_reason
  end

  test "discount_for calcula porcentaje o cantidad, sin superar el total" do
    percent = Coupon.create!(code: "P10", discount_percent: 10)
    assert_equal BigDecimal("2.42"), percent.discount_for(BigDecimal("24.20"))

    fixed = Coupon.create!(code: "F5", discount_amount: 5)
    assert_equal BigDecimal("5"), fixed.discount_for(BigDecimal("24.20"))
    assert_equal BigDecimal("3"), fixed.discount_for(BigDecimal("3")), "nunca más que el total"
  end

  test "los emails de aviso se validan y se separan por comas" do
    coupon = Coupon.new(code: "N", discount_percent: 5, notify_emails: "uno@x.com, dos@y.com")
    assert coupon.valid?
    assert_equal %w[uno@x.com dos@y.com], coupon.notify_email_list

    coupon.notify_emails = "esto-no-es-email"
    assert_not coupon.valid?
  end

  test "register_use! incrementa usos y avisa a cada promotor" do
    coupon = Coupon.create!(code: "PROMO", discount_amount: 5, notify_emails: "a@x.com b@y.com")
    order = Order.create!(number: "PR-TEST", customer_name: "Cliente", email: "c@example.com",
                          phone: "612345678", address: "Calle 1", city: "Madrid", postal_code: "28001",
                          province: "Madrid", country: "España (Península)", total: 20, coupon_discount: 5)

    assert_emails 2 do
      coupon.register_use!(order)
      perform_enqueued_jobs
    end
    assert_equal 1, coupon.reload.uses_count
  end
end
