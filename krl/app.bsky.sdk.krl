ruleset app.bsky.sdk {
  meta {
    provide sendPost
  }
  global {
    url = "https://bsky.social/xrpc/com.atproto."
    sendPost = defaction(text){
      recURL = url + "repo.createRecord"
      hdrs = {"Authorization":"Bearer "+ent:accessJwt}
.klog("hdrs")
      post = {
        "$type": "app.bsky.feed.post",
        "text": text,
        "createdAt":time:now(),
      }
      record = {
        "repo":ent:identifier,
        "collection":"app.bsky.feed.post",
        "record":post,
      }
.klog("record")
      http:post(recURL,headers=hdrs,json=record) setting(resp)
      return resp
    }
  }
  rule configure {
    select when bsky new_configuration
      identifier re#(.+)#
      accessJwt re#(.+)#
      setting(id,jwt)
    fired {
      ent:identifier := id
      ent:accessJwt := jwt
    }
  }
}
