ruleset microblog_poster {
  meta {
    use module app.bsky.sdk alias sdk
    shares index, last_response, last_response_content
  }
  global {
    index = function(_headers){
      <<<!DOCTYPE HTML>
<html>
  <head>
    <title>Microblog Poster</title>
    <meta charset="UTF-8">
<style type="text/css">
body { font-family: "Helvetica Neue",Helvetica,Arial,sans-serif; }
</style>
  </head>
  <body>
<h1>Microblog Poster</h1>
<form action="#{meta:host}/sky/event/#{meta:eci}/none/microblog_poster/new_post">
<textarea name="text"></textarea>
<button type="submit">Post</button>
</form>
#{ent:last_response.isnull() => "" | <<
<hr>
<p>Last response: #{ent:last_response.get("status_code")}</p>
<p>#{last_response_content().encode()}</p>
>>}
  </body>
</html>
>>
    }
    last_response = function(){
      ent:last_response
    }
    last_response_content = function(){
      ent:last_response.get("content").decode()
    }
  }
  rule sendPost {
    select when microblog_poster new_post
    sdk:sendPost(event:attrs.get("text")) setting(resp)
    fired {
      ent:last_response := resp
    }
  }
  rule checkPostResponse {
    select when microblog_poster new_post
    pre {
      status_code = ent:last_response.get("status_code")
.klog("status_code")
      content = ent:last_response.get("content").decode()
      expired_token = content.get("error") == "ExpiredToken"
    }
    if status_code >= 400 || expired_token then noop()
    fired {
      raise bsky event "token_expired"
      raise microblog_poster event "retry_needed" attributes event:attrs
    }
  }
  rule redirectBack {
    select when microblog_poster new_post
    pre {
      referrer = event:attrs{"_headers"}.get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
  rule sendPostSecondAttempt {
    select when microblog_poster retry_needed
    sdk:sendPost(event:attrs.get("text")) setting(resp)
    fired {
      ent:last_response := resp
    }
  }
}
