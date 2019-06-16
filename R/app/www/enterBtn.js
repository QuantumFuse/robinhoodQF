$(document).keyup(function(event) {
  if ($("#user_pwd").is(":focus") && (event.key == "Enter")) {
    $("#sign_in").click();
    }
});