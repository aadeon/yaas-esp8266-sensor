
url = "http://google.com"


function firstRequest(callback)
  print("First request, connecting to " .. url)
  http.get(url, nil,
    function(code, data)
        print("First response: " .. code .. ", data: \n" .. (data or "<none>"))
        --callback()
        node.task.post(callback)
    end)
end

function secondRequest()
  print("Second request, connecting to " .. url)
  http.get(url, nil,
    function(code, data)
        print("Second response: " .. code .. ", data: \n" .. (data or "<none>"))
    end)
end


firstRequest(secondRequest)


