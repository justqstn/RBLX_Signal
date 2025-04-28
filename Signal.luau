--!strict
--[[
	Signal (v1.0)
	By just_qstn (@LennyGamer228)

  	"cool thing ig"
--]]


type IConnection_fields = {
	Signal: 			  any,
	Function: 			  (...any) -> nil,
}

type ISignal_fields = {
	Connections: 		  {[IConnection]: IConnection},
	Name: 				  string?,
	Yielded:			  boolean,
}

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection


export type ISignal = typeof(setmetatable({} :: ISignal_fields,	Signal))
export type IConnection = typeof(setmetatable({} :: IConnection_fields,	Connection))

local Signals: {[string]: ISignal} = {}




-- Creates new Signal.
function Signal.new(Name: string?): ISignal
	local result = setmetatable({} :: ISignal_fields, Signal)
	result.Connections = {}
	result.Yielded = false
	
	if Name then
		result.Name = Name
		Signals[Name] = result 
	end
	
	return result
end

-- Gets signal by name.
function Signal.Get(Name: string): ISignal
	return Signals[Name]
end

-- Yields thread until signal is a created
function Signal.WaitForSignal(Name: string, Timeout: number): ISignal
	local start = tick()
	Timeout = Timeout or 15
	
	while not Signals[Name] do
		task.wait()
		if start ~= -1 then
			if tick() - start > Timeout then
				start = -1
				warn(`It seems like there is no Signal "${Name}".`)
			end
		end
	end 
	
	return Signals[Name]
end

-- Yields thread until Signal will be fired.
function Signal:Wait()
	self.Yielded = true
	while self.Yielded do
		task.wait()
	end
end

-- Fire all connections.
function Signal:Fire(...)
	self.Yielded = false
	for _, connection in pairs(self.Connections) do
		connection.Function(...)
	end
end

-- Fire all connections in async mode.
function Signal:FireAsync(...)
	self.Yielded = false
	for _, connection in pairs(self.Connections) do
		coroutine.wrap(connection.Function)(...)
	end
end

-- Connect a new function to signal and return Connection.
function Signal:Connect(Function: (...any) -> nil): IConnection
	local result = setmetatable({} :: IConnection_fields, Connection)
	result.Signal = self
	result.Function = Function
	
	table.insert(self.Connections, result)
	return result
end

-- Disconnects all Connections of a signal.
function Signal:DisconnectAll() 
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
	end
	
	table.clear(self.Connections)
end

-- Disconnects connection from a signal.
function Connection:Disconnect()
	self.Signal.Connections[self] = nil
	self.Function = nil
	self.Signal = nil
	setmetatable(self, nil)
end



return Signal
