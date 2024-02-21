ruleset app.bsky.sdk {
  meta {
    use module io.picolabs.wrangler alias wrangler
    provide sendPost
  }
  global {
    url = "https://bsky.social/xrpc/com.atproto."
    ok = function(resp){
      resp.get("status_code") == 200 => "OK" | "ExpiredToken"
    }
    self = function(){
      wrangler:channels("system,self").head().get("id")
    }
    refresh = defaction(){
      rsURL = url + "server.refreshSession"
      hdrs = {
        "Authorization": "Bearer " + ent:refreshJwt,
      }
      http:post(rsURL,headers=hdrs) setting(resp)
      return resp.get("content").decode()
    }
    refreshThenPost = defaction(text){
      recURL = url + "repo.createRecord"
      hdrs = {"Authorization":"Bearer "+ent:accessJwt}
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
      every {
        refresh() setting(tokens)
        event:send({"eci":self(),"domain":"bsky","type":"new_tokens","attrs":tokens})
        http:post(recURL,headers=hdrs,json=record) setting(resp2)
      }
      return resp2
    }
    checkPost = defaction(text,resp){
      resp_ok = resp.ok()
      choose resp_ok {
        OK => noop()
        ExpiredToken => refreshThenPost(text) setting(resp2)
      }
      return resp_ok => resp | resp2
    }
    sendPost = defaction(text){
      recURL = url + "repo.createRecord"
      hdrs = {"Authorization":"Bearer "+ent:accessJwt}
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
      every {
        http:post(recURL,headers=hdrs,json=record) setting(resp)
        checkPost(text,resp) setting(resp2)
      }
      return resp.ok() => resp | resp2
    }
  }
  rule configure {
    select when bsky new_configuration
      identifier re#(.+)#
      accessJwt re#(.+)#
      setting(did,jwt)
    fired {
      ent:identifier := did
      ent:accessJwt := jwt
      ent:refreshJwt := event:attrs{"refreshJwt"}
    }
  }
  rule refreshSession {
    select when bsky token_expired
    pre {
      rsURL = url + "server.refreshSession"
      hdrs = {
        "Authorization": "Bearer " + ent:refreshJwt,
      }
    }
    http:post(rsURL,headers=hdrs) setting(resp)
    fired {
      raise bsky event "response_received" attributes resp
      raise bsky event "new_tokens" attributes resp if resp{"status_code"}==200
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
      raise bsky event "new_tokens" attributes resp if resp{"status_code"}==200
    }
  }
  rule saveTokens {
    select when bsky new_tokens
    pre {
      content = event:attrs{"content"}.decode()
.klog("content")
      did = content{"did"}
.klog("did")
      jwt = content{"accessJwt"}
.klog("jwt")
      rfs = content{"refreshJwt"}
.klog("rfs")
    }
    fired {
      ent:identifier := did
      ent:accessJwt := jwt
      ent:refreshJwt := rfs
    }
  }
}
