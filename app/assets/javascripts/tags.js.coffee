$(document).ready ->

  $("html.tags.show form").live "ajax:beforeSend", (evt, xhr, settings) ->
    $(".loading", this).css("visibility", "visible")
    $("input[type=submit]", this).attr("disabled", "true")

  $("html.tags form").live "ajax:success", (evt, xhr, settings) ->
    $(this).replaceWith(xhr);

