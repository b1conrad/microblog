ruleset microblog_poster.krl {
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
  </body>
</html>
>>
    }
  }
}
