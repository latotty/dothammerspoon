function authedRequest(method, url, payload, callback)
  local accessToken = hs.settings.get('imgur_access_token')
  local headers = {Authorization = "Bearer " .. accessToken}

  return hs.http.doAsyncRequest(url, method, payload, headers, callback)
end

function checkAuth(callback)
  local clientID = hs.settings.get('imgur_client_id')
  local clientSecret = hs.settings.get('imgur_client_secret')
  local refreshToken = hs.settings.get('imgur_refresh_token')
  local accessToken = hs.settings.get('imgur_access_token')
  
  if clientID ~= nil and clientSecret ~= nil and refreshToken ~= nil and accessToken ~= nil then
    return callback(true)
  end
  
  local result = nil
  result = hs.dialog.blockAlert('Do you want to authenticate with Imgur?', '', 'YES', 'NO')
  if result ~= 'YES' then
    return callback(false)
  end

  result = hs.dialog.blockAlert('Please register an imgur application', 'https://api.imgur.com/oauth2/addclient', 'Done', 'Cancel')
  if result ~= 'Done' then
    return callback(false)
  end

  result, clientID = hs.dialog.textPrompt('Please enter the Client ID', '', '', 'OK', 'Cancel')
  if result ~= 'OK' or #clientID == 0 then
    return callback(false)
  end

  result, clientSecret = hs.dialog.textPrompt('Please enter the Client secret', '', '', 'OK', 'Cancel')
  if result ~= 'OK' or #clientSecret == 0 then
    return callback(false)
  end

  local authURL = 'https://api.imgur.com/oauth2/authorize?client_id=' .. clientID .. '&response_type=pin'

  local pin = nil
  result, pin = hs.dialog.textPrompt('Please authenticate with Imgur and enter PIN', authURL, '', 'Done', 'Cancel')
  if result ~= 'Done' or #pin == 0 then
    return callback(false)
  end

  local url = "https://api.imgur.com/oauth2/token"
  local payload = 'client_id=' .. clientID .. '&client_secret=' .. clientSecret .. '&pin=' .. pin .. '&grant_type=pin'

  return hs.http.doAsyncRequest(url, 'POST', payload, nil, function (responseStatus, responseJSON) 
    if responseStatus ~= 200 then
      hs.dialog.blockAlert('Error while trying to authenticate with Imgur', responseJSON)
      return checkAuth(callback)
    end
  
    local response = hs.json.decode(responseJSON)
    refreshToken = response['refresh_token']
    accessToken = response['access_token']
  
    hs.settings.set('imgur_client_id', clientID)
    hs.settings.set('imgur_client_secret', clientSecret)
    hs.settings.set('imgur_refresh_token', refreshToken)
    hs.settings.set('imgur_access_token', accessToken)
  
    return callback(true)
  end)
end

function checkToken(callback)
  return checkAuth(function (ok) 
    if not ok then 
      return 
    end

    return authedRequest('GET', 'https://api.imgur.com/3/account/me/settings', nil, function (responseStatus, responseJSON) 
      if responseStatus == 200 then
        return callback(true)
      end
    
      local clientID = hs.settings.get('imgur_client_id')
      local clientSecret = hs.settings.get('imgur_client_secret')
      local refreshToken = hs.settings.get('imgur_refresh_token')
      local accessToken = hs.settings.get('imgur_access_token')
    
      local url = "https://api.imgur.com/oauth2/token"
      local payload = 'client_id=' .. clientID .. '&client_secret=' .. clientSecret .. '&refresh_token=' .. refreshToken .. '&grant_type=refresh_token&expires_in=0'
    
      return hs.http.doAsyncRequest(url, 'POST', payload, nil, function (responseStatus, responseJSON) 
        if responseStatus ~= 200 then
          hs.dialog.blockAlert('Error while trying to authenticate with Imgur', responseJSON)
      
          hs.settings.clear('imgur_client_id')
          hs.settings.clear('imgur_client_secret')
          hs.settings.clear('imgur_refresh_token')
          hs.settings.clear('imgur_access_token')
      
          return checkToken(callback)
        end
      
        local response = hs.json.decode(responseJSON)
        refreshToken = response['refresh_token']
        accessToken = response['access_token']
      
        hs.settings.set('imgur_refresh_token', refreshToken)
        hs.settings.set('imgur_access_token', accessToken)
      
        return callback(true)
      end)
    end)
  end)
end

function uploadImageFromClipboard()
  return checkToken(function (ok)
    if not ok then
      return
    end

    local image = hs.pasteboard.readImage()
  
    if not image then
      hs.alert.show('No image on clipboard, could not upload it to Imgur')
      return false
    end
  
    local tempfile = "/tmp/tmp.png"
    image:saveToFile(tempfile)
    local b64 = hs.execute("base64 -i "..tempfile)
    b64 = hs.http.encodeForQuery(string.gsub(b64, "\n", ""))
  
    local payload = 'type=base64&image=' .. b64
    
    return authedRequest('POST', 'https://api.imgur.com/3/upload.json', payload, function (responseStatus, responseJSON)
      if responseStatus ~= 200 then
        hs.dialog.blockAlert('Error while trying to upload Imgur', responseJSON)
        return false
      end
    
      local response = hs.json.decode(responseJSON)
      local imageURL = response.data.link
    
      hs.pasteboard.setContents(imageURL)
      hs.alert.show('Uploaded to Imgur, URL on clipboard')
    end)
  end)
end

hs.hotkey.bind(hyper, "4", uploadImageFromClipboard)