ruleset app.bsky.sdk {
  meta {
    use module io.picolabs.wrangler alias wrangler
    provide sendPost
  }
  global {
    url = "https://bsky.social/xrpc/com.atproto."
    recURL = url + "repo.createRecord"
    rsURL = url + "server.refreshSession"
    self = function(){
      wrangler:channels("system,self").head().get("id")
    }
    refresh = defaction(){
      hdrs = {
        "Authorization": "Bearer " + ent:refreshJwt,
      }
      http:post(rsURL,headers=hdrs) setting(resp)
      return resp.get("content").decode()
    }
    makeRecordFromText = function(text){
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
      record
    }
    refreshThenPost = defaction(text){
      hdrs = function(tokens_map){
        {"Authorization":"Bearer "+tokens_map.get("accessJwt")}
      }
      record = makeRecordFromText(text)
      every {
        refresh() setting(tokens)
        event:send({"eci":self(),"domain":"bsky","type":"new_tokens","attrs":tokens})
        http:post(recURL,headers=hdrs(tokens),json=record) setting(resp2)
      }
      return resp2
    }
    checkPost = defaction(text,resp){
      resp_ok = resp.get("status_code") == 200
      resp_switch = resp_ok => "OK" | "ExpiredToken"
      choose resp_switch {
        OK => noop()
        ExpiredToken => refreshThenPost(text) setting(resp2)
      }
      return resp_ok => resp | resp2
    }
    sendPost = defaction(text){
      hdrs = {"Authorization":"Bearer "+ent:accessJwt}
      record = makeRecordFromText(text)
      every {
        http:post(recURL,headers=hdrs,json=record) setting(resp)
        checkPost(text,resp) setting(resp2)
      }
      return resp2
    }
  }
  rule refreshSession {
    select when bsky token_expired
    pre {
      hdrs = {
        "Authorization": "Bearer " + ent:refreshJwt,
      }
    }
    http:post(rsURL,headers=hdrs) setting(resp)
    fired {
      raise bsky event "new_tokens" attributes resp{"content"}.decode()
        if resp{"status_code"}==200
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
      raise bsky event "new_tokens" attributes resp{"content"}.decode()
        if resp{"status_code"}==200
    }
  }
  rule saveTokens {
    select when bsky new_tokens
    pre {
      did = event:attrs{"did"}
.klog("did")
      jwt = event:attrs{"accessJwt"}
.klog("jwt")
      rfs = event:attrs{"refreshJwt"}
.klog("rfs")
    }
    if did && jwt && rfs then noop() // sanity
    fired {
      ent:identifier := did
      ent:accessJwt := jwt
      ent:refreshJwt := rfs
    }
  }
}
