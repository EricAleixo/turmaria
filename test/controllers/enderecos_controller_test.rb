require "test_helper"

class EnderecosControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get enderecos_index_url
    assert_response :success
  end

  test "should get show" do
    get enderecos_show_url
    assert_response :success
  end
end
