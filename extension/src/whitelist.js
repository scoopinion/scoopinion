
var whitelist;
var whitelistUrl = serverUrl + "/sites.json";

var userUrl = serverUrl + "/users/" + userID + ".json";

var whitelistUpdateDelay = 28800000;
var whitelistLastUpdate = 0;

var languages = {
  en: 1
};

var whitelistInitialized = false;

initializeWhitelist();


function initializeWhitelist() {
    $.getJSON(whitelistUrl, function(data) {
		  whitelist = data;
		  console.log("Whitelist has " + whitelist.length + " sites");
		  if (!whitelistInitialized) {
		      searchHistory();
		      whitelistInitialized = true;
		  }

	      });
}

function refreshWhitelist() {
    var time = new Date().getTime();
    if (time - whitelistLastUpdate < whitelistUpdateDelay) {
	return;
    }
    whitelistLastUpdate = time;
    initializeWhitelist();
}

function isWhitelisted(url) {

    refreshWhitelist();

    if (!whitelist) {
	return false;
    }

    for (var i = 0; i < whitelist.length; ++i) {
	var site = whitelist[i];
	if (url.indexOf(site.url) != -1) { // FIXME not foolproof
	    return true;
	}
	
    }

    return false;
}

function searchHistory() {

    searchSite(0);

}

function searchSite(i) {

    var site = whitelist[i];


    chrome.history.search({ text: site.url, maxResults: 100, startTime: new Date().getTime() - 5000000000 }, function(results) {

			      results = results.filter(function(result) {
						return result.url.indexOf(site.url + "/") != -1; 
					     });

			      results = results.map(function(result) { return result.url.replace(/\?.*/, ""); });

			      results = jQuery.unique(results);

			      if (results.length > 2) {

				  console.log("Searching with " + site.url);
				  console.log(results);

				  if (languages[site.language]) {
				      languages[site.language]++;
				  } else {
				      languages[site.language] = 1;
				  }

			      }

			      nextSite(i);
			  });

	

}

function nextSite(i) {
    if (i + 1 < whitelist.length) {
	var site = whitelist[i + 1];
	if (languages[site.language]) {
	    nextSite(i + 1);
	} else {
	    searchSite(i + 1);	
	}

    } else {
	delete languages[null];
	console.log(userUrl);
	console.log(languages);
	
	$.ajax(userUrl, { type: "put", data: { 
			      user: { 
				  extension: 1, languages: languages 
			      },
			      user_credentials: apiKey } });
	
    }
    
}