require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @order = orders(:one)
  end

  test "should get index" do
    get orders_url
    assert_response :success
  end

  test "should get new" do
    get new_order_url
    assert_response :success
  end

  test "should create order" do
    assert_difference('Order.count') do
      post orders_url, params: { order: { brand_id: @order.brand_id, customer_name: @order.customer_name, name: @order.name, order_detail: @order.order_detail, payment_address: @order.payment_address, price: @order.price, shiping_address: @order.shiping_address, source: @order.source, status: @order.status, tracking_id: @order.tracking_id } }
    end

    assert_redirected_to order_url(Order.last)
  end

  test "should show order" do
    get order_url(@order)
    assert_response :success
  end

  test "should get edit" do
    get edit_order_url(@order)
    assert_response :success
  end

  test "should update order" do
    patch order_url(@order), params: { order: { brand_id: @order.brand_id, customer_name: @order.customer_name, name: @order.name, order_detail: @order.order_detail, payment_address: @order.payment_address, price: @order.price, shiping_address: @order.shiping_address, source: @order.source, status: @order.status, tracking_id: @order.tracking_id } }
    assert_redirected_to order_url(@order)
  end

  test "should destroy order" do
    assert_difference('Order.count', -1) do
      delete order_url(@order)
    end

    assert_redirected_to orders_url
  end
end
