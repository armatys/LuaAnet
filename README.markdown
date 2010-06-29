LuaAnet - Lua bindings to anet library (from redis project)

### Compilation

Use [premake](http://industriousone.com/premake) to generate appropriate build files. E.g run `premake4 gmake` to generate a Makefile. Then execute `make config=release32` or `make config=release64` to compile.

### Usage:

	require "anet"
	
	local fd, err = anet.tcpserver(8080, "127.0.0.1")
	
	while true do
		local clientfd, ip, port = anet.accept(fd, true, true)
		local n, msg = anet.read(clientfd, 4096)
		print("Read " .. n .. " bytes")
		
		if n > 0 then
			io.write(msg)
		elseif n < 0 then
			-- print error message
			print(msg)
			break
		elseif n == 0 then
			-- client closed connection
			anet.close(clientfd)
		end
	end