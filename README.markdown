LuaAnet - Lua bindings to anet library (from redis project)

### Compilation

Use luarocks to compile and install:

    $ [sudo] luarocks make

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
