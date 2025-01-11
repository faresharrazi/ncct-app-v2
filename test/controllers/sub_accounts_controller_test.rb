require "test_helper"

class SubAccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sub_accounts_index_url
    assert_response :success
  end

  test "should get show" do
    get sub_accounts_show_url
    assert_response :success
  end

  test "should get new" do
    get sub_accounts_new_url
    assert_response :success
  end

  test "should get create" do
    get sub_accounts_create_url
    assert_response :success
  end

  test "should get edit" do
    get sub_accounts_edit_url
    assert_response :success
  end

  test "should get update" do
    get sub_accounts_update_url
    assert_response :success
  end

  test "should get destroy" do
    get sub_accounts_destroy_url
    assert_response :success
  end
end
