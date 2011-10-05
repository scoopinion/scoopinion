window.add_fb_friends =  (path, callback = false) ->
  FB.getLoginStatus (response) ->
    if response.session
      FB.api
        method: "fql.query"
        query: "SELECT uid FROM user WHERE has_added_app=1 and uid IN (SELECT uid2 FROM friend WHERE uid1 =me())"
      , (response) ->
        response = $.map(response, (user) ->
          user.uid
        )
        $.post path, "friends[]": response, (data) ->
          if typeof callback == "function"
            callback(data)

$(document).ready ->

  $("abbr.timeago").timeago();

  $("[title]").tooltip({ position: "center right", offset : [ 0, 10 ] })

  $("a.delete").live "ajax:beforeSend", ->
    parent = $(this).parents($(this).attr("data-parent-to-delete") + ":first")
    parent.fadeOut('fast', -> $(this).remove())

  $("a[data-show]").attr("href", "javascript:void(0)");
  $("a[data-show]").live "click", ->
    $($(this).attr("data-show")).toggle();

  $("[data-update-url]").live "reload", ->
    toReplace = $(this)
    $.get(toReplace.attr("data-update-url")+".html", (data) ->
            toReplace.replaceWith(data))

  $("[data-toggle]").attr("href", "javascript:void(0)");
  $("[data-toggle]").live "click", ->
    $(this).toggleClass("opened");
    $($(this).attr("data-toggle")).toggle();


  $('.profile-menu a.out').click ->
    FB.logout (response) ->
      return true
  $(".invite_fb_friends").click ->
    FB.ui
      method: "apprequests"
      message: "I'm sharing the news I read in Scoopinion. You are one of the few interesting people I'd like to follow."
  if $('html').hasClass('extension') && !$('input[name=friends-updated-at]').attr('value')
    add_fb_friends $('input[name=friends-updated-at]').attr('rel')

  $('#person-name').toggle ->
      $('#profile-menu-wrapper').insertAfter('header').show()
  , ->
      $('#profile-menu-wrapper').hide();
  $("html").click ->
    $('#profile-menu-wrapper').hide();
  $("#person-name").click (event) ->
    event.stopPropagation()

  $("a.app").click ->
    $(this).parents("form:first").submit()
    return false

  $("[data-tab]").attr("href", "javascript:void(0)")
  $("[data-tab]").live "click", ->
    $("[data-tab]").removeClass("active")
    $(this).addClass("active")
    $("#list .tab").addClass("hidden")
    $("#list .tab." + $(this).attr("data-tab")).removeClass("hidden")