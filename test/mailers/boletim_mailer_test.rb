require "test_helper"

class BoletimMailerTest < ActionMailer::TestCase
  test "enviar_boletim" do
    mail = BoletimMailer.enviar_boletim
    assert_equal "Enviar boletim", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
