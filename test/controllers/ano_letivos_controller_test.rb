require "test_helper"

class AnoLetivosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ano_letivo = ano_letivos(:one)
  end

  test "should get index" do
    get ano_letivos_url
    assert_response :success
  end

  test "should get new" do
    get new_ano_letivo_url
    assert_response :success
  end

  test "should create ano_letivo" do
    assert_difference("AnoLetivo.count") do
      post ano_letivos_url, params: { ano_letivo: { ano: @ano_letivo.ano, data_fim: @ano_letivo.data_fim, data_inicio: @ano_letivo.data_inicio, status: @ano_letivo.status } }
    end

    assert_redirected_to ano_letivo_url(AnoLetivo.last)
  end

  test "should show ano_letivo" do
    get ano_letivo_url(@ano_letivo)
    assert_response :success
  end

  test "should get edit" do
    get edit_ano_letivo_url(@ano_letivo)
    assert_response :success
  end

  test "should update ano_letivo" do
    patch ano_letivo_url(@ano_letivo), params: { ano_letivo: { ano: @ano_letivo.ano, data_fim: @ano_letivo.data_fim, data_inicio: @ano_letivo.data_inicio, status: @ano_letivo.status } }
    assert_redirected_to ano_letivo_url(@ano_letivo)
  end

  test "should destroy ano_letivo" do
    assert_difference("AnoLetivo.count", -1) do
      delete ano_letivo_url(@ano_letivo)
    end

    assert_redirected_to ano_letivos_url
  end
end
