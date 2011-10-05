
$(document).ready ->

        testExtension = ->
                if ($("meta[name=scoopinion-extension-version]").attr("content"))
                        $("#header-right .app").html("App OK!")
                $("#header-right .app").css("display", "block")

        setTimeout(testExtension, 1000);

