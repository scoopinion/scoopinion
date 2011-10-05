$(document).ready(
    function() {

	var serverUrl = "SERVER_URL";
	var articleInfoUrl = serverUrl + "/articles/";
	var commentsURL = serverUrl + "/comments/";	

	var articleID;
	var userID;
	var apiKey;
	var article;
	var displayName;
	var tabID = $.query.get("tabID");

	if (localStorage.huomenetDisabled == "true" || localStorage.huomenetDisabled == true) {
	    render();
	} else {
	    getArticleInfo();	    
	}


	$("#whitelist").live("click", function() {
				 
				 console.log("button click");
				 chrome.extension.sendRequest(
				     {
					 tabID: tabID,
					 method: "refresh-whitelist"
				     }
				 );

			     });


	$("#disable").html(localStorage.huomenetDisabled == "true" ? "Enable Scoopinion" : "Disable Scoopinion");

	$("#new_comment").autoResize({limit: 120});

	$("#forget").live("click", 
			  function() {

			      if (!article.forget) {

				  chrome.extension.sendRequest(
				      { 
					  tabID: tabID,
					  method: "forget"
				      }
				  );

				  article.forget = true;

				  $.ajax({
					     type: "delete",
					     url: visitURL(),
					     data: {
						 user_credentials: apiKey
					     }
					 });

			      } else {
				  

				  article.forget = false;
				  chrome.extension.sendRequest(
				      { 
					  tabID: tabID,
					  method: "remember"
				      }
				  );

			      }

			      render();
			  });

	$("#disable").live(
	    "click", 
	    function() {

		console.log(localStorage.huomenetDisabled);

		if (localStorage.huomenetDisabled == "false") {
		    localStorage.huomenetDisabled = true;

		    chrome.extension.sendRequest(
			{ 
			    tabID: tabID,
			    method: "disable"
			}
		    );


		} else {		    
		    localStorage.huomenetDisabled = false;
		    article = null;
		    chrome.extension.sendRequest(
			{ 
			    tabID: tabID,
			    method: "enable"
			}
		    );
		}
		
		console.log(localStorage.huomenetDisabled);

		render();
	    });


	
	$("#submit_comment").live("click",
			       function(e) {

				       $.ajax({
						  type: "post",
						  url: commentsURL,
						  data: {
						      user_credentials: apiKey,
						      comment: {
							  body: $("#new_comment").val(),
							  user_id: userID,
							  article_id: articleID
						      }
						  }

					      });

				       $('<p class="namebox"><a href="#">' + displayName + '</a> ' + $("#new_comment").val() + '</p>').appendTo("#comments");
				       $("#new_comment").val("");
				   
			       });
	

	function getArticleInfo() {
	    chrome.extension.sendRequest(
		{ 
		    tabID: tabID,
		    method: "getInfo"
		}, 
		
		function(response) {

		    articleID = response.articleID;
		    userID = response.userID;
		    apiKey = response.apiKey;
		    article = response.article;

		    console.log(article);
			
		    $.getJSON(userURL(), function(data) {
				  displayName = data.display_name;
				  $("#username").html(data.display_name);				  
				  $("#username").attr("href", profileURL());
			      });

		    $.getJSON(articleURL(), function(data) {
				  if (data) {
				      article.comments = data.comments;
				  }
				  render();
			      });
		}
	    );
	    
	}

	function render() {

	    $("#loading").fadeOut("fast");

	    if (articleID === undefined) {
		$(".message").html("Scoopinion doesn't think this is a news article.");
		$(".article-required").hide();
	    }

	    if (article) {
		$("a.stats").attr("href", serverUrl + "/articles/" + articleID);
		$("#forget").html(article.forget ? "Remember this article" : "Forget this article");
		$(".article-required").show();
	    }

	    $("#disable").html(localStorage.huomenetDisabled == "true" ? "Enable Scoopinion" : "Disable Scoopinion");

	    if (localStorage.huomenetDisabled == "false") {

		$("#comments").html("");

		if (article && article.comments) {
		    
		    for (var i = 0; i < article.comments.length; ++i) {
			var comment = article.comments[i];
			var commentBox = $('<p class="namebox"><a href="#"></a> <span class="name"></span></p>');
			
			$("a", commentBox).text(comment.user.display_name);
			$(".name", commentBox).text(comment.body);
			
			commentBox.appendTo("#comments");
		    }

		}

		$("#forget").show();
		$(".commentblock").show();

		if (articleID === undefined) {
		    $(".article-required").hide();
		}
				

	    } else {
		
		$("#forget").hide();
		$(".commentblock").hide();
		$(".message").hide();

	    }
	    
	}


	function userURL() {
	    return serverUrl + "/users/" + userID + ".json";
	}

	function profileURL() {
	    return serverUrl + "/users/" + userID;
	}

	function articleURL() {
	    return serverUrl + "/articles/" + articleID + ".json";
	}

	function visitURL() {
	    return serverUrl + "/visits/" + articleID + ".json";
	}

    });