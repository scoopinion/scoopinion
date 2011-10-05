$(document).ready(
    function() {

	if (test_group()) {

	    if (window.location.host.indexOf("www.hs.fi") != -1) {

		var iframe_url = serverUrl + "/articles/" + encodeURIComponent(window.location.hostname + window.location.pathname).replace(/\./g, "$dot") + "/visitors?iframe=true&user_credentials=" + apiKey;

		var comments_url = serverUrl + "/articles/" + encodeURIComponent(window.location.hostname + window.location.pathname).replace(/\./g, "$dot") + "/comments?iframe=true&user_credentials=" + apiKey;
		$(".byline").before("<div style=\"clear: both\"><iframe style=\"border: 0;\" height=\"50\" scrolling =\"no\" width=\"100%\" src=\"" + iframe_url + "\"></iframe></div>");					


	    }

	}

	function test_group() {
	    return jQuery.inArray(userID, [ "1", "2", "3", "4", "5", "6", "7", "9", "27", "31", "32", "51", "53", "77", "71" ]) !== -1;
	}

    });