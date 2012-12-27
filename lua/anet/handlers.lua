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
local string = require 'string'

local _M = {}
setfenv(1, _M)

family = 'armatys:anet'

function accept(event, perun, thread)
  local clb = function(evtype, id)
    local cfd, ipOrErrMsg, portOrErrCode = anetc.accept(event.fd, true, true)
    if cfd then
      local ok, errmsg, errcode = anetc.nonblock(event.fd)
      if ok then
        perun.spawn(thread, cfd, ipOrErrMsg, portOrErrCode)
      else
        perun.spawn(thread, nil, errmsg, errcode)
      end
    else
      perun.spawn(thread, nil, ipOrErrMsg, portOrErrCode)
    end
  end

  perun.setlistener(event.fd, perun.Event.read, clb)
  return true
end

function read(event, perun, thread)
  local clb = function(evtype, id)
    local nread, content, err = anetc.read(event.fd, event.n)
    if err and err == anetc.EAGAIN then
      read(event, perun, thread)
    else
      perun.spawn(thread, nread, content, err)
    end
  end

  perun.setlistener(event.fd, perun.Event.read, clb)
  return true
end

function write(event, perun, thread)
  local clb = function(evtype, id)
    local nwritten, errmsg, err = anetc.write(event.fd, event.msg)
    if err and err == anetc.EAGAIN then
      write(event, perun, thread)
    else
      perun.spawn(thread, nwritten, errmsg, err)
    end
  end

  perun.setlistener(event.fd, perun.Event.write, clb)
  return true
end

function writeall(event, perun, thread)
  local clb = function(evtype, id)
    local nwritten, errmsg, err = anetc.write(event.fd, string.sub(event.msg, event.written + 1))
    if err and err == anetc.EAGAIN then
      writeall(event, perun, thread)
    elseif err then
      perun.spawn(thread, nwritten, errmsg, err)
    else
      if nwritten == 0 then
        perun.spawn(thread, event.written)
      else
        event.written = event.written + nwritten
        if event.written >= #event.msg then
          perun.spawn(thread, event.written)
        else
          writeall(event, perun, thread)
        end
      end
    end
  end

  perun.setlistener(event.fd, perun.Event.write, clb)
  return true
end

return _M
