$(document).ready ->

        showNotifications = ->
                $("#notifications").fadeIn("slow")

        setTimeout(showNotifications, 1000)


        updateNotifications = ->
                $(".edit_notification").submit()

        setTimeout(updateNotifications, 10000)

        $("#notifications li").click ->
                $(this).find(".edit_notification").submit()
                $(this).fadeOut()

