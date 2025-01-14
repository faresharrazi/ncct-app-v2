require "test_helper"

class MainTransactionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get main_transactions_index_url
    assert_response :success
  end

  test "should get show" do
    get main_transactions_show_url
    assert_response :success
  end

  test "should get new" do
    get main_transactions_new_url
    assert_response :success
  end

  test "should get edit" do
    get main_transactions_edit_url
    assert_response :success
  end
end
