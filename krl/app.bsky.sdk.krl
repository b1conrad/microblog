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
  rule getAccessToken {
    select when bsky session_expired
      identifier re#(.+)#
      password re#(.+)#
      setting(id,pswd)
    pre {
      atURL = url + "server.createSession"
      authn = {
        "identifier": id,
        "password": pswd,
      }
    }
    http:post(atURL,json=authn) setting(resp)
    fired {
      raise bsky event "new_token" attributes resp if resp{"status_code"}==200
    }
  }
  rule saveToken {
    select when bsky new_token
    pre {
      content = event:attrs{"content"}.decode()
.klog("content")
      did = content{"did"}
.klog("did")
      jwt = content{"accessJwt"}
.klog("jwt")
    }
    fired {
      ent:identifier := did
      ent:accessJwt := jwt
    }
  }
}
