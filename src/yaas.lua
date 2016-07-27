
require "config"

tokenUrl = 'https://api.yaas.io/hybris/oauth2/v1/token'
scopes = 'hybris.document_manage hybris.document_view'
docRepoUrl = 'https://api.yaas.io/hybris/document/v1'
deviceId = node.chipid()

dhtPin = 4

function tableToString(t)
  local result = ""
  for k,v in pairs(t) do
    -- print("k: '"..k.."', v: '" .. v .. "'")
    result = result .. ( (result == "") and "" or ", ") .. k .. ": " .. v
    -- print(k,v)
  end
  return result
end


function startWifi(callback)

  wifi.setmode(wifi.STATION)

  wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(t)
    print ("Wifi connected, " .. tableToString(t))
  end)

  wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function()
    print ("Wifi disconnected")
  end)

  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(t)
    print ("Wifi got IP, " .. tableToString(t))
    callback()
  end)

  print("Initializing Wifi ", wifiSsid)
  wifi.sta.config(wifiSsid, wifiPassword)
end


function getToken(callback)
  print("Connecting to " .. tokenUrl)
  http.post(tokenUrl,
    'content-type: application/x-www-form-urlencoded\r\n',
    'grant_type=client_credentials&client_id=' .. clientId .. '&client_secret=' .. clientSecret .. '&scope=' .. scopes,
    function(code, data)
      if (code < 200 or code >299) then
        print("HTTP request failed, code: " .. code .. ", data: " .. (data or "<empty>") )
      else
        print('Received', code, data)
        local tokenJson = cjson.decode(data)
        accessToken = tokenJson.access_token
        print('Access token', accessToken)
        node.task.post(callback)
      end
    end)
end


function getDefaultHeaders()
  return 'content-type: application/json\r\nAuthorization: Bearer ' .. accessToken .. '\r\n'
end

function createDevice(callback)
  local url = docRepoUrl .. '/' .. tenant .. '/' .. client .. '/data/devices/' .. deviceId .. '?upsert=true&partial=true'
  --local postUrl = tokenUrl .. 'aaa'
  local headers = getDefaultHeaders()
  --  local body = [[
  --    {
  --      "sensors": {
  --        "temperature": { "readings": [] },
  --        "humidity": { "readings": [] }
  --      }
  --    }
  --  ]]
  local body = [[
    {   
    } 
  ]]

  print("POSTing to " .. url)
  print("Body: " .. body)

  http.put(url,
    headers,
    body,
    function(code, data)
      print("PUT device result, code: " .. code .. ", data: " .. (data or "<none>"))
      node.task.post(callback)
    end
  )
end

function postReading(valueTable)
  local postUrl = docRepoUrl .. '/' .. tenant .. '/' .. client .. '/data/devices/' .. deviceId .. '/readings'
  local headers = getDefaultHeaders()

  -- TODO Add timestamp
  local json = cjson.encode(valueTable)

  print("POSTing to " .. postUrl)
  print("Headers: " .. headers)
  print("Body: " .. json)

  http.post(postUrl,
    headers,
    json,
    function(code, data)
      print("POST readings result, code: " .. code .. ", data: " .. data)

      if (code == 401) then
        print("Token expired, renewing")
        wifiStarted()
      end
    end
  )
end

function wifiStarted()
  getToken(tokenRetrieved)
end

function tokenRetrieved()
  createDevice(deviceCreated)
end

function deviceCreated()
  startReadings()
end

readingsTimer = 0

function startReadings()
  print("Registering read-DHT timer")
  tmr.register(readingsTimer, 60000, tmr.ALARM_AUTO, readDhtAndPost)
  tmr.start(readingsTimer)
end

function readDhtAndPost()
  print("Reading DHT")
  local status, temp, humi, temp_dec, humi_dec = dht.read(dhtPin)

  print("Read DHT. Status " .. status.. ", temp: " .. temp .. ", humi: " .. humi)

  if (status == 0) then
    local values = {
      t = temp,
      h = humi
    }
    postReading(values)
  end
end

startWifi(wifiStarted)



