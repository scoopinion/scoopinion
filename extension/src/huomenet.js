$(document).ready(
    function() {
	
	var delay = 1000;
	var sleep = 15000;
	var readingDelay = 500;

	ACTIVE_TAB = null;

	disabled = false;
	updateDisabled();
	setTimeout(innerLoop, delay);

	var version;
	getVersion(function (ver) { version = ver; });


	setTimeout(updateActiveTab, 1000);
	
	function updateActiveTab() {

	    if (tabs[ACTIVE_TAB]) {
		var a = tabs[ACTIVE_TAB];

		if (new Date().getTime() - a.lastMove < 15000) {
		    a.total_time++;
		    a.touch();
		}

	    }
	    setTimeout(updateActiveTab, 1000);
	}

	function updateDisabled() {	    

	    disabled = localStorage.huomenetDisabled;

	    if (disabled === undefined) {
		disabled = false;
		localStorage.huomenetDisabled = false;
	    }

	    console.log("Disabled is now " + disabled);

	}

	function innerLoop() {
	    for (a in articles) {
		var article = articles[a];

		if (article.whitelisted && !article.forget && !article.firstSent && article.title) {

		    send(article);
		    article.firstSent = true;	    
		}
		
		if (article.whitelisted && !article.forget && !article.sent && article.title && new Date().getTime() - article.updatedAt > sleep) {
		    send(article);
		    article.sent = true;
		}
	    }
	    setTimeout(innerLoop, delay);
	}

	function getVersion(callback) {
	    var xmlhttp = new XMLHttpRequest();
	    xmlhttp.open('GET', 'manifest.json');
	    xmlhttp.onload = function (e) {
		var manifest = JSON.parse(xmlhttp.responseText);
		callback(manifest.version);
	    };
	    xmlhttp.send(null);
	}

	var articles = {
    
	};

	var tabs = {

	};

	function getArticle(url) {
	    if (articles[url] === undefined) {
		articles[url] = {
		    url: url,
		    scrollPercent: 0,
		    sent: false,
		    score: 0,
		    scrollMax: 0,
		    forget: true,
		    total_time: 0,
		    lastMove: new Date().getTime(),
		    metadata: {}
		};

		articles[url].touch = function() {
		    this.updatedAt = new Date().getTime();
		    this.sent = false;
		};

		console.log("created " + url);

		articles[url].touch();
	    }
	    return articles[url];

	}


	chrome.extension.onRequest.addListener(
	    function(request, sender, sendResponse) {

		var a;


		if (request.event) {
		    
		    if (sender.tab && articles[sender.tab.url]) {

			ACTIVE_TAB = sender.tab.id;

			a = getArticle(sender.tab.url);

			if (a.metadata[request.event] === undefined) {
			    a.metadata[request.event] = 0;
			}

			a.metadata[request.event] = a.metadata[request.event] + 1;


		    }
		    
		    return;

		}
 


		if (sender.tab && articles[sender.tab.url]) {

		    ACTIVE_TAB = sender.tab.id;

		    a = getArticle(sender.tab.url);

		    if (!a.startTime) {
			a.startTime = new Date().getTime();
		    }

		    a.time = new Date().getTime() - a.startTime;

		    if (request.scrollPixels > a.scrollMax) {
			a.scrollMax = request.scrollPixels;
		    }

		    a.score = (a.time / 1000 + a.scrollMax / 100) / 20;
		    a.score = Math.min(a.score, 10);

		    a.scrollPercent = request.scrollPercent;
		    if (request.title) {
			a.title = request.title;			
		    }

		    a.referrer = request.referrer;
		    a.tabID = sender.tab.id;
		    a.description = request.description;   
		    
		    a.image = request.image;

		    if (disabled == "true") {
			a.forget = true;
		    } else {
			a.forget = false;
		    }

		    a.lastMove = new Date().getTime();

		    a.touch();

		    tabs[a.tabID] = a;


		    sendResponse({
				     version: version
				 });
		    
		}

		if (request.tabID && tabs[request.tabID]) {
		    
		    a = tabs[request.tabID];

		    if (request.method == "getInfo") {

			var response = { 
					 article: a,
					 articleID: a.id, 
					 userID: userID, 
					 visitID: a.visitID,
					 apiKey: apiKey
				     };

			if (a.id === undefined) {
			    console.log("article id is undefined");
			}

			console.log(response);

			sendResponse(response);

		    } else if (request.method == "forget") {
			
			a.forget = true;

		    } else if (request.method == "remember") {
			
			a.forget = false;

		    } else if (request.method == "enable" || request.method == "disable") {

			updateDisabled();
			render(a);

		    } 		
		}

		if (request.method == "refresh-whitelist") {
		    initializeWhitelist();
		}


		if (a) {
		    render(a);
		}		
	    }
	);

	chrome.history.onVisited.addListener(
	    function(historyItem) {
		
		if (historyItem.url.startsWith("https")) {
		    return;
		}

		var visitedUrl = historyItem.url;

		chrome.history.getVisits(
		    { url: visitedUrl }, 
		    function(results) {

			if (results[0].transition != "auto_subframe") {  // Ignore automatic external content (ads etc.)
			    
			    var article = getArticle(visitedUrl);
			    article.title = historyItem.title;
			    article.url = visitedUrl;

			    article.whitelisted = isWhitelisted(article.url);

			}});
	    });


	function send(article) {

	    console.log("sending " + article.url);
	    console.log(article);

	    var visit = {
		score: article.score,
		referrer: article.referrer
	    };

	    if (article.visitID !== undefined) {
		visit.total_time = article.total_time;
		$.extend(visit, article.metadata);
	    }

	    console.log(visit);

	    var articleParam = {
		url: article.url,
		title: article.title,
		description: article.description,
		image_url: article.image
	    };

	    $.post(uploadUrl, {
		       visit: visit,
		       article: articleParam,
		       extension_version: version,
		       user_credentials: apiKey
		   },
		   function(data) {

		       console.log("got data");
		       console.log(data);

		       var a = getArticle(article.url);

		       console.log(a);

		       if (a.visitID == null) {
			   a.visitID = data.visit.id;
			   a.total_time = a.total_time + data.visit.total_time;
			   
			   console.log("Filling with remote data");
			   $.each([ "link_click", "right_click", 
				    "mouse_move", "link_hover", 
				    "arrow_up", "arrow_down", 
				    "scroll_down", "scroll_up" ], function(i, val) {
				      if (a.metadata[val] === undefined) {
					  a.metadata[val] = 0;
				      }
				      a.metadata[val] += data.visit[val];
				  });
		       }

		       console.log(a);

		       a.id = data.article.id;
		       a.remoteScore = data.article.score;
		       a.comments = data.article.comments;
		   });

	}


	function render(a) {

	    var icon, popup;

	    if (a.whitelisted === false) {
		icon = "icon_inactive.png";
		popup = "not_news.html";
	    } else {
		icon = "icon_active.png";

		if (a.comments > 0) {
		    icon = "icon_active_comment.png";
		}

		popup = "popup.html?tabID=" + a.tabID;
	    }
	    
	    if (localStorage.huomenetDisabled == "true") {
		icon = "icon_disabled.png";
	    }	  

	    chrome.pageAction.show(a.tabID);
	    chrome.pageAction.setIcon({ path: icon, tabId: a.tabID });
	    chrome.pageAction.setPopup({ popup: popup, tabId: a.tabID });

	}

});

