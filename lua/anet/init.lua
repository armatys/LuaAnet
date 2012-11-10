--[[
 * Copyright (c) 2010-2012 Mateusz Armatys
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
--]]

local anetc = require 'anetc'
local coroutine = require 'coroutine'
local handlers = nil

pcall(function()
  local perun = require 'perun'
  if perun then
    handlers = require 'anet.handlers'
    perun.register(handlers)
  end
end)

local _M = {}
setfenv(1, _M)

local function canDoAsync()
  return coroutine.running() ~= nil and handlers
end

--- Accept a new connection on listening socket.
-- @param fd NUMBER socket file descriptor
-- @return NIL or NUMBER client file descriptor
-- @return NUMBER or STRING port of the client or error message
-- @return STRING or NUMBER IP of the client or error code
function accept(fd)
  if not canDoAsync() then
    return anetc.accept(fd, true, true)
  end

  local event = {
    family = handlers.family,
    name = 'accept',
    fd = fd
  }
  return coroutine.yield(event)
end

--- Close a socket file descriptor.
-- @param fd NUMBER socket file descriptor
-- @return BOOLEAN true on success; false on error
-- @return NIL or STRING error message
-- @return NIL or NUMBER error code
function close(fd)
  return anetc.close(fd)
end

--- Read data from a socket.
-- @param fd NUMBER socket file descriptor
-- @param n NUMBER of bytes to read
-- @return NIL or NUMBER of read bytes (zero indicates end of file)
-- @return STRING read bytes or error message
-- @return NIL or NUMBER error code
function read(fd, n)
  if not canDoAsync() then
    return anetc.read(fd, n)
  end

  local event = {
    family = handlers.family,
    name = 'read',
    fd = fd,
    n = n
  }
  return coroutine.yield(event)
end

--- Resolve a host name to a string in IPv4 dotted-decimal notation.
-- @param host STRING host name to resolve
-- @return BOOLEAN true if success; false on errors
-- @return STRING resolved name or error message
function resolve(host)
  return anetc.resolve(host)
end

--- Connect to a tcp endpoint.
-- @param addr STRING hostname or IP of the target
-- @param port NUMBER of the port
-- @return NIL or NUMBER file descriptor for the connection
-- @return NIL or STRING error message
-- @return NIL or NUMBER error code
function tcpconnect(addr, port)
  if not canDoAsync() then
    return anetc.tcpconnect(addr, port)
  else
    return anetc.tcpnbconnect(addr, port)
  end
end

--- Enable sending of keep-alive messages.
-- @param fd NUMBER socket file descriptor
-- @return BOOLEAN true on success, false on error
-- @return NIL or STRING error message
-- @return NIL or NUMBER error code
function tcpkeepalive(fd)
  return anetc.tcpkeepalive(fd)
end

--- Disable a buffering algorithm.
-- @param fd NUMBER socket file descriptor
-- @return BOOLEAN true on success, false on error
-- @return NIL or STRING with error message
-- @return NIL or NUMBER error code
function tcpnodelay(fd)
  return anetc.tcpnodelay(fd)
end

--- Create a new TCP server, bind and listen on a given port and address.
-- @param port NUMBER port number
-- @param addr STRING hostname or IP
-- @return NIL or NUMBER with server socket file descriptor
-- @return NIL or STRING error message
-- @return NIL or NUMBER error code
function tcpserver(port, addr)
  local fd, errmsg, errcode = anetc.tcpserver(port, addr)
  if fd then
    if canDoAsync() then
      local ok, errmsg, errcode = anetc.nonblock(fd)
      if ok then
        return fd, nil, nil
      else
        return nil, errmsg, errcode
      end
    else
      return fd, nil, nil
    end
  else
    return nil, errmsg, errcode
  end
end


--- Write a message to a socket.
-- @param fd NUMBER socket file descriptor
-- @param msg STRING bytes to write
-- @return NIL or NUMBER of bytes written
-- @return STRING error message
-- @return NUMBER error code
function write(fd, msg)
  if not canDoAsync() then
    return anetc.write(fd, msg)
  end

  local event = {
    family = handlers.family,
    name = 'write',
    fd = fd,
    msg = msg
  }
  return coroutine.yield(event)
end

return _M
