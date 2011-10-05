$(document).ready ->

  $(".predictions form").live "ajax:success", (evt, xhr, settings) ->
    $(this).parents(".article:first").remove()
    $(".article:first").trigger("click")
    $(".article:first").addClass("view")
    if $("#list .article").length == 0
      $("#list").load($("#list").attr("data-update-url"), ->
        $(".article:first").removeClass("view")
        $(".article:first").trigger("click")
      )

  $(".predictions form").live "ajax:beforeSend", ->
    $(this).parents(".article:first").slideUp()
    if $("#list .article").length == 1
      $("#list .loading").css("visibility", "visible")
      $("#sidebar .sidebar-article").html("")
