require "application_system_test_case"

class AnoLetivosTest < ApplicationSystemTestCase
  setup do
    @ano_letivo = ano_letivos(:one)
  end

  test "visiting the index" do
    visit ano_letivos_url
    assert_selector "h1", text: "Ano letivos"
  end

  test "should create ano letivo" do
    visit ano_letivos_url
    click_on "New ano letivo"

    fill_in "Ano", with: @ano_letivo.ano
    fill_in "Data fim", with: @ano_letivo.data_fim
    fill_in "Data inicio", with: @ano_letivo.data_inicio
    fill_in "Status", with: @ano_letivo.status
    click_on "Create Ano letivo"

    assert_text "Ano letivo was successfully created"
    click_on "Back"
  end

  test "should update Ano letivo" do
    visit ano_letivo_url(@ano_letivo)
    click_on "Edit this ano letivo", match: :first

    fill_in "Ano", with: @ano_letivo.ano
    fill_in "Data fim", with: @ano_letivo.data_fim
    fill_in "Data inicio", with: @ano_letivo.data_inicio
    fill_in "Status", with: @ano_letivo.status
    click_on "Update Ano letivo"

    assert_text "Ano letivo was successfully updated"
    click_on "Back"
  end

  test "should destroy Ano letivo" do
    visit ano_letivo_url(@ano_letivo)
    accept_confirm { click_on "Destroy this ano letivo", match: :first }

    assert_text "Ano letivo was successfully destroyed"
  end
end
