$(document).ready ->

  $('#create_friendships').click (event) ->
    event.preventDefault()
    t = $(this)
    originalText = t.html()
    t.html('Loading<span class="dots"></span>')
    dots = t.find('.dots')
    loadingDots = ->
      dots.append('.')
      dots.empty() if dots.html().length > 3
    setInterval loadingDots, 500

    initAdd = (response, elseFunction = false) ->
      if response.session
        window.add_fb_friends t.attr('rel'), (friendCount) ->
          t.html(friendCount + ' friends added.')
          window.location.reload()
      else
        elseFunction() if $.isFunction(elseFunction)

    FB.getLoginStatus (response) ->
      initAdd(response, -> FB.login ((response) -> initAdd(response)))



  update_compatibilities = ->
    if $("p.compatibility[data-compatibility=-1]").length > 0
      $.getJSON("/friendships", (data) ->
        $.each(data, (index, friendship) ->

          if friendship.compatibility > -1
            selector = "p.compatibility[data-friend-id=" + friendship.friend_id + "]"
            console.log selector
            console.log(friendship.compatibility)
            $(selector).html(Math.round(friendship.compatibility * 100) + " %")
            $(selector).attr("data-compatibility", friendship.compatibility)
          )

        $("#list ul").jSort
          item: "li"
          sort_by: "p.compatibility"
          order: "desc"
          sort_by_attr: true
          attr_name: "data-compatibility"
          is_num: true
        )

    if $("p.compatibility[data-compatibility=-1]").length > 0
      setTimeout(update_compatibilities, 3000)

  setTimeout(update_compatibilities, 3000)