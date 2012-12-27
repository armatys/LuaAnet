local anet = require 'anet'
local hyperparser = require 'hyperparser'
local perun = require 'perun'

local usePerun = true
local response = "HTTP/1.1 200 OK\r\nContent-Length: 14\r\nConnection: close\r\nContent-Type: text/plain\r\n\r\nHello world!\r\n"

local function write_response(cfd)
  local written, errmsg, errcode = anet.writeall(cfd, response, i)
  if not written then
    print("Write error", errmsg)
  end
  anet.close(cfd)
end

local function handler(cfd)
  local shouldRead = true
  local settings = {
    msgcomplete = function()
      shouldRead = false
      write_response(cfd)
    end
  }
  local request = hyperparser.request(settings)

  while shouldRead do
    local nread, content, errcode = anet.read(cfd)

    if not nread then
      anet.close(cfd)
      break
    elseif nread > 0 then
      local nparsed = request:execute(content)
      if nparsed ~= nread then
        anet.close(cfd)
        break
      end
    else
      anet.close(cfd)
      break
    end
  end
end

local function server()
  local port = 8080
  local fd, errmsg, errcode = anet.tcpserver(port, "127.0.0.1")
  if not fd then
    print("Error in tcpserver", errmsg)
    return
  end

  print("Listening on port " .. port .. "..")

  while true do
    local cfd, portOrErrMsg, ipOrErrCode = anet.accept(fd)
    if not cfd then
      print("Error in accept", portOrErrMsg)
    else
      if usePerun then
        perun.spawn(handler, cfd)
      else
        handler(cfd)
      end
    end
  end
end


if usePerun then
  perun.spawn(server)
  perun.main() -- loop for single-threaded; main for grand central dispatch
else
  server()
end
