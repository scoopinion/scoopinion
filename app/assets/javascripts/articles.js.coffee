
$('#news').ready ->
  $("[data-onload]").each ->
    $(this).hide().load $(this).attr("data-onload"), ->
      $(this).fadeIn('fast')
      $("#news").trigger("loaded")


$(document).ready ->

  $("form.new_article_tag").live "ajax:beforeSend", ->
    $(".loading", $(this)).css("visibility", "visible")

  $("form.new_article_tag").live "ajax:success", (evt, data) ->
    sidebar = $(this).parents(".sidebar-article:first")
    if data.status == "ok"
      sidebar.trigger("reload")
    else if data.status == "confirmation_needed"
      result = confirm("Are you sure you want to create the new tag '" + data.new_tag + "'?")
      if result
        $.post $(this).attr("action"), $(this).serialize() + "&create_new_tag=true", (data) ->
          sidebar.trigger("reload")
      else
        $(".loading", $(this)).css("visibility", "hidden")

  $("a.delete-tag").live "ajax:beforeSend", ->
    $("form.new_article_tag .loading", $(this).parents(".sidebar-article:first")).css("visibility", "visible")

  $("a.delete-tag").live "ajax:success", ->
    $(this).parents(".sidebar-article:first").trigger "reload"

  $("#sort_order select, #sort_order input").live "change", ->
    querystr = "?" + $(this).parents("form:first").serialize()
    window.location = querystr

  $('.article .headline').live "click", (evt) ->
    _gaq.push( [ "_trackEvent", "article", $(this).attr("href") ] )

  $('.article .meta a').live "click", (evt) ->
    evt.stopPropagation()

  $('.article .article-content a').live "click", (evt) ->
    $(this).parents('.article').addClass('visited')

  fb = $('html').hasClass('fb')

  $('.article').live "click", (evt) ->

    url = $(this).attr('data-replace-with')

    if fb
      $.get url, (data) ->
        $.fancybox(data,
          {
          'autoDimensions' : false,
          'autoScale'    : false,
          'width'      : 600,
          'height'     : 'auto',
          'onComplete':   ->
              $("#fancybox-wrap").css({'top':'10px', 'position' : 'fixed'})
          })
      ,"html"

    else
      return true if $(this).hasClass("view")

      animateSpeed = 150

      if $('#scroller').hasClass('fixed')
        movingdiv = $('#scroller')
        offset = $('body').innerWidth() - movingdiv.offset().left - movingdiv.outerWidth()
      else
        movingdiv = $('#sidebar')
        offset = 0


      movingdiv.css('right' : offset).animate({'right' : offset + 400 + 'px'}, animateSpeed)
      $("#news .sidebar-loading").show();

      $('.article').removeClass('view highlight')

      $(this).addClass('view')
      viewedArticle = $(this)

      setTimeout(->
        if viewedArticle.hasClass("view")
          viewedArticle.addClass("visited")
      , 10000)

      $.get url, (data) ->

        _gaq.push(['_trackPageview', url + "/sidebar"]);

        $('#scroller').html(data)
        $("abbr.timeago").timeago();
        movingdiv.show()
        $("#news .sidebar-loading").hide();
        movingdiv.animate({'right' : offset + 'px'}, animateSpeed, setSidebar)
      ,"html"

  $(window).scroll (event) ->
    setSidebar()

  bottomBoundary = 120
  if $("#sidebar") && $("#sidebar").offset()
    window.topBoundary = $("#sidebar").offset().top

  setDefaultSidebarHeight = ->
    unless landingPage()
      $('#scroller').css('height' : $(window).height() - window.topBoundary + 'px') unless $('#scroller').hasClass('fixed')

  setFixedSidebarHeight = ->
    unless landingPage()
      y = $(window).scrollTop()
      maxScroll = $(document).height() - $(window).height()

      if y >= window.topBoundary
        $('#scroller').addClass('fixed')
        $('#news .sidebar-loading').addClass('fixed')
      else
        $('#scroller').removeClass 'fixed'
        $('#news .sidebar-loading').removeClass('fixed')

      if y >= maxScroll - bottomBoundary
        $('#scroller').css('height' : $(window).height() - bottomBoundary)
      else
        $('#scroller').css('height' : $(window).height() - 50)

  setSidebar = ->
    setFixedSidebarHeight()
    setDefaultSidebarHeight()
    $('html').removeClass("landing") unless landingPage()
    $('#scroller').css('right' : 'auto')

  $('.actions').live "click", (evt) ->
    navi = $(this).next('.actions-nav')
    if navi.is(":visible") then navi.hide() else navi.show()
    evt.stopPropagation()

  $(window).resize ->
    unless landingPage()
      setFixedSidebarHeight()

  $("#news").live "loaded", ->

    if $("#sidebar")
      window.topBoundary = $("#sidebar").offset().top

    $("abbr.timeago").timeago();
    $("[title]").tooltip({ position: "center right", offset : [ 0, 10 ] })
    $("#main").removeAttr("style")
    setDefaultSidebarHeight()
    FB.Canvas.setSize() if fb

  landingPage = ->
    $("html").hasClass("landing") && $("#sidebar .landing").length > 0


  $("[data-feed-param], [data-feed-source]").each ->
    $(this).attr("href", "javascript:void(0)")

  $("[data-feed-param]").click ->
    _gaq.push(['_trackPageview', document.URL + "?" + $(this).html().toLowerCase()])
    $(".heading a").removeClass "active"
    $(this).addClass "active"
    $("#feed").attr "data-feed-additional", $(this).attr("data-feed-param")
    $("#feed").trigger "getfeed"

  $("[data-feed-source]").click ->
    _gaq.push(['_trackPageview', document.URL + "?" + $(this).html().toLowerCase()])
    $(".heading a").removeClass "active"
    $(this).addClass "active"
    $("#feed").trigger "getfeed", $(this).attr("data-feed-source")


  $("#feed").live "getfeed", (evt, customURL)->
    $(this).html("")
    $(this).addClass("loading")

    if customURL
      url = customURL
    else
      url = "/feed?" + $(this).attr("data-feed-params") + "&" + $(this).attr("data-feed-additional")

    $(this).load(url, ->
      unless landingPage()
        $(".article:first", $(this)).trigger("click")
      $(this).removeClass("loading"))

  $("#feed").trigger("getfeed")

