ruleset microblog_poster {
  meta {
    use module app.bsky.sdk alias sdk
    shares index
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
<textarea name="post"></textarea>
<button type="submit">Post</button>
</form>
  </body>
</html>
>>
    }
  }
}
