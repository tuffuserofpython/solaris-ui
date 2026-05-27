-- libui/utilities/Signal.lua
-- Lightweight event emitter for LibUI

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (Connection) -> (),
	Connected: boolean,
}

export type SignalType = {
	Connect: (SignalType, fn: (...any) -> ()) -> Connection,
	Once: (SignalType, fn: (...any) -> ()) -> Connection,
	Fire: (SignalType, ...any) -> (),
	Disconnect: (SignalType, connection: Connection) -> (),
	DisconnectAll: (SignalType) -> (),
	Destroy: (SignalType) -> (),
}

function Signal.new(): SignalType
	local self = setmetatable({}, Signal)
	self._connections = {}
	self._destroyed = false
	return self
end

function Signal:Connect(fn: (...any) -> ()): Connection
	assert(type(fn) == "function", "Signal:Connect requires a function")

	local connection = {
		Connected = true,
		_fn = fn,
		_signal = self,
	}

	connection.Disconnect = function(conn)
		if conn.Connected then
			conn.Connected = false
			conn._fn = nil
			for i, c in ipairs(self._connections) do
				if c == conn then
					table.remove(self._connections, i)
					break
				end
			end
		end
	end

	table.insert(self._connections, connection)
	return connection
end

function Signal:Once(fn: (...any) -> ()): Connection
	assert(type(fn) == "function", "Signal:Once requires a function")

	local connection
	connection = self:Connect(function(...)
		connection:Disconnect()
		fn(...)
	end)

	return connection
end

function Signal:Fire(...: any)
	if self._destroyed then return end

	-- snapshot the connections list to avoid mutation during iteration
	local connections = table.clone(self._connections)
	for _, connection in ipairs(connections) do
		if connection.Connected then
			task.spawn(connection._fn, ...)
		end
	end
end

function Signal:Disconnect(connection: Connection)
	if connection and connection.Connected then
		connection:Disconnect()
	end
end

function Signal:DisconnectAll()
	for _, connection in ipairs(self._connections) do
		connection.Connected = false
		connection._fn = nil
	end
	table.clear(self._connections)
end

function Signal:Destroy()
	self:DisconnectAll()
	self._destroyed = true
end

return Signal
