$(document).ready ->

  $("form.new_comment").live "ajax:beforeSend", (evt, xhr, settings) ->
    $(".loading", this).css("visibility", "visible")
    $("#new_comment input[type=submit]").attr("disabled", "true")

  $("form.new_comment").live "ajax:success", (evt, xhr, settings) ->
    data =
      name: $(".news-viewed h2 a").html()
      message: "commented on an article in Scoopinion."
      description: "Scoopinion helps you keep up with what your friends are reading."
      link: 'http://www.scoopinion.com/articles/'+xhr.id
      picture: xhr.image_url

    shareOnFB(data) if $('#fb_comment').is(':checked')

    parent = $(this).parents("div[data-update-url]:first")
    $.get(parent.attr("data-update-url")+".html", (data) ->
            parent.replaceWith(data))
    $("#new_comment input[type=submit]").attr("disabled", "true")

  permissionsNeeded = 'publish_stream'

  shareOnFB = (data) ->
    FB.login ((response) ->
      if response.session
        if response.perms
          FB.api('/me/feed', 'post', data, (response) ->
          )
    ), perms: permissionsNeeded


