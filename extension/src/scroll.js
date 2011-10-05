
onScroll();

document.addEventListener("scroll", onScroll);
document.addEventListener("scroll", scroll);
document.addEventListener("mousemove", onScroll);
document.addEventListener("mousemove", mouseMove);
document.addEventListener("contextmenu", rightClick);
document.addEventListener("keydown", keyDown);

lastScroll = 0;

$(document).ready(
    function() {
		      
	$("a").live("click", linkClick);
	$("a").live("hover", linkHover);

});

function recordEvent(event) {
    chrome.extension.sendRequest({ event: event });
}

function linkClick(event) {
    recordEvent("link_click");
}

function rightClick(event) {
    recordEvent("right_click");
}

function mouseMove(event) {
    recordEvent("mouse_move");
}

function linkHover(event) {
    recordEvent("link_hover");
}

function keyDown(event) {
    switch(event.keyCode) {
    case 38:
	recordEvent("arrow_up");
	break;
	
    case 40:
	recordEvent("arrow_down");
	break;
    }
}

function scroll(event) {
    if (getScroll() > lastScroll) {
	recordEvent("scroll_down");
    } else {
	recordEvent("scroll_up");
    }

    lastScroll = getScroll();
}

function onScroll(event) {


    chrome.extension.sendRequest(
	{ 
	    scrollPercent: getScrollPercent(), 
	    scrollPixels: getScroll(), 
	    title: document.title, 
	    referrer: document.referrer,
	    description: getDescription(),
	    image: getImage()
	}, function(response) { 
	      $("meta[name=scoopinion-extension-version]").attr("content", response.version);
	  });

}

function getDescription() {
    if ($("meta[property='og:description']").length > 0) {
	return $("meta[property='og:description']").attr("content");
    }
    return $("meta[name=description]").attr("content");
}

function getImage() {
    if ($("meta[property='og:image']").length > 0) {
	return $("meta[property='og:image']").attr("content");
    }
    return $("link[rel=image_src]").attr("href");
}

function getScrollPercent() {
    return Math.ceil( 100 * (document.body.scrollTop + window.innerHeight) / document.body.scrollHeight );
}

function getScroll() {
    return document.body.scrollTop + window.innerHeight;
}