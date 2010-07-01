/* Lua bindings to anet library.
 *
 * Copyright (c) 2010 Mateusz Armatys
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *   * Neither the name of Redis nor the names of its contributors may be used
 *     to endorse or promote products derived from this software without
 *     specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <lua.h>
#include <lauxlib.h>
#include "zmalloc.h"
#include "anet.h"

#define buf_size 65536

static char err[ANET_ERR_LEN];
static char recv_buf[buf_size];
static char ip_buf[16];

static int l_tcpconnect(lua_State* L) {
    const char* addr = luaL_checkstring(L, 1);
    int port = luaL_checknumber(L, 2);
    int ret = anetTcpConnect(err, addr, port);
    lua_pushnumber(L, ret);
    if (ret < 0) {
        lua_pushstring(L, err);
        return 2;
    }
    
    return 1;
}

static int l_tcpnonblockconnect(lua_State* L) {
    const char* addr = luaL_checkstring(L, 1);
    int port = luaL_checknumber(L, 2);
    int ret = anetTcpNonBlockConnect(err, addr, port);
    lua_pushnumber(L, ret);
    if (ret < 0) {
        lua_pushstring(L, err);
        return 2;
    }
    
    return 1;
}

static int l_read(lua_State* L) {
    int fd = luaL_checknumber(L, 1);
    int count = luaL_checknumber(L, 2);
    if (count > buf_size) {
        luaL_error(L, "Maximum buffer size is %d", buf_size);
    }
    int nread = read(fd, recv_buf, count);
    
    lua_pushnumber(L, nread);
    
    if (nread < 0) {
        const char* errmsg = (const char*)strerror(errno);
        lua_pushstring(L, errmsg);
        lua_pushinteger(L, errno);
        return 3;
    }
    
    lua_pushlstring(L, recv_buf, nread);
    return 2;
}

static int l_write(lua_State* L) {
    int fd = luaL_checknumber(L, 1);
    size_t len;
    const char* msg = luaL_checklstring(L, 2, &len);
    
    int written = write(fd, msg, len);
    
    lua_pushnumber(L, written);
    
    if (written < 0) {
        const char* errmsg = (const char*)strerror(errno);
        lua_pushstring(L, errmsg);
        lua_pushinteger(L, errno);
        return 3;
    }
    
    return 1;
}

static int l_accept(lua_State* L) {
    int fd = luaL_checknumber(L, 1);
    char* ip = NULL;
    int* port = NULL;
    
    //optional info to return (ip, port)
    if (lua_toboolean(L, 2) == 1) {
        ip = malloc(sizeof(char)*16);
    }
    if (lua_toboolean(L, 3) == 1) {
        port = malloc(sizeof(int));
    }
    
    int ret = anetAccept(err, fd, ip, port);
    lua_pushnumber(L, ret);
    
    if (ret < 0) {
        lua_pushstring(L, err);
        return 2;
    }
    
    int retcount = 1;
    if (ip != NULL) {
        lua_pushstring(L, ip);
        free(ip);
        retcount++;
    }
    if (port != NULL) {
        lua_pushnumber(L, *port);
        free(port);
        retcount++;
    }
    
    return retcount;
}

static int l_tcpserver(lua_State* L) {
    int port = luaL_checknumber(L, 1);
    const char* bindaddr = NULL;
    if (!lua_isnil(L, 2)) bindaddr = luaL_checkstring(L, 2);
    
    int ret = anetTcpServer(err, port, bindaddr);
    lua_pushnumber(L, ret);
    
    if (ret < 0) {
        lua_pushstring(L, err);
        return 2;
    }
    
    return 1;
}

static int l_resolve(lua_State* L) {
    const char* host = luaL_checkstring(L, 1);
    
    int ret = anetResolve(err, host, ip_buf);
    lua_pushnumber(L, ret);
    
    if (ret < 0) {
        lua_pushstring(L, err);
    } else {
        lua_pushstring(L, ip_buf);
    }
    
    return 2;
}

static int l_close(lua_State* L) {
    int fd = luaL_checknumber(L, 1);
    int ret = close(fd);
    
    lua_pushnumber(L, ret);
    return 1;
}

static int l_nonblock(lua_State* L) {
    int fd = luaL_checknumber(L, 1);
    int ret = anetNonBlock(err, fd);
    lua_pushnumber(L, ret);
    
    if (ret < 0) {
        lua_pushstring(L, err);
        return 2;
    }
    
    return 1;
}

static int l_tcpnodelay(lua_State* L) {
    int fd = luaL_checknumber(L, 1);
    int ret = anetTcpNoDelay(err, fd);
    lua_pushnumber(L, ret);
    
    if (ret < 0) {
        lua_pushstring(L, err);
        return 2;
    }
    
    return 1;
}

static int l_tcpkeepalive(lua_State* L) {
    int fd = luaL_checknumber(L, 1);
    int ret = anetTcpKeepAlive(err, fd);
    lua_pushnumber(L, ret);
    
    if (ret < 0) {
        lua_pushstring(L, err);
        return 2;
    }
    
    return 1;
}

static const struct luaL_Reg anetlib [] = {
    {"tcpconnect", l_tcpconnect},
    {"tcpnbconnect", l_tcpnonblockconnect},
    {"read", l_read},
    {"write", l_write},
    {"tcpserver", l_tcpserver},
    {"accept", l_accept},
    {"resolve", l_resolve},
    {"close", l_close},
    {"nonblock", l_nonblock},
    {"tcpnodelay", l_tcpnodelay},
    {"tcpkeepalive", l_tcpkeepalive},
    {NULL, NULL}
};


/**
 * Register functions to lua_State.
 */
LUALIB_API int luaopen_anet(lua_State* L) {
    luaL_register(L, "anet", anetlib);
    
    return 1;
}