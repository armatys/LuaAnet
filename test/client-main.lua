local anet = require 'anet'
local hyperparser = require 'hyperparser'
local perun = require 'perun'

local usePerun = true

function main()
  local fd, errmsg, errcode = anet.tcpconnect("makenika.pl", 80)

  if not fd then
    print(errmsg)
    return
  end

  anet.write(fd, "GET / HTTP/1.1\r\nHost: www.makenika.pl\r\n\r\n")

  local shouldRead = true
  local settings = {
    body = function(content)
      io.write(content)
    end,
    msgcomplete = function()
      shouldRead = false
      anet.close(fd)
    end,
    headerfield = function(a)
      io.write(a)
    end,
    
    headervalue = function(a)
      io.write(" -> " .. a .. "\n")
    end
  }
  local request = hyperparser.response(settings)

  while shouldRead do
    local nread, content, errcode = anet.read(fd, 4096)

    if not nread then
      anet.close(fd)
      break
    elseif nread > 0 then
      local nparsed = request:execute(content)
      if nparsed ~= nread then
        anet.close(fd)
        break
      end
    else
      anet.close(fd)
      break
    end
  end
end

if usePerun then
  perun.spawn(main)
  perun.loop()
else
  main()
end
