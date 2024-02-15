ruleset app.bsky.sdk {
  meta {
    provide sendPost
  }
  global {
    url = "https://bsky.social/xrpc/com.atproto.server."
    recURL = url + "createRecord"
    sendPost = defaction(text){
      hdrs = {"Authorization":"Bearer "+ent:accessJwt}
      record = {
        "repo":ent:identifier,
        "collection":"app.bsky.feed.post",
        "record":text,
        "createdAt":time:now(),
      }
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
