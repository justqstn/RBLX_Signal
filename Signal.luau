--!native
--[[
	Signal (v1.0)
	By just_qstn (@LennyGamer228)

  	"cool thing ig"
--]]



export type IConnection = {
	Signal: 			  ISignal,
	Disconnect: 		  (self: IConnection) -> 	  nil,
	Function: 			  (...any) -> any,
} 

export type ISignal = {
	Connections: 		  {[IConnection]: IConnection},
	Name: 				  string?,
	Yielded:			  boolean,
	
	new: 				  (Name: string?) -> ISignal,
	Get:				  (Name: string) -> ISignal,
	WaitForSignal:		  (Name: string, Timeout: number?) -> ISignal,
	
	Wait:				  (self: ISignal) -> nil,
	Destroy: 			  (self: ISignal) -> nil,
	Fire: 				  (self: ISignal, ...any) -> nil,
	FireAsync:			  (self: ISignal, ...any) -> nil,
	Connect: 			  (self: ISignal, (...any) -> any) -> IConnection,
}



local Signals: ISignal = {}

local Signal: ISignal = {}
Signal.__index = Signal

local Connection: IConnection = {}
Connection.__index = Connection



-- Creates new Signal.
function Signal.new(Name: string?): ISignal
	local result: ISignal = setmetatable({}, Signal)
	result.Connections = {}
	if Name then
		result.Name = Name
		Signals[Name] = result 
	end
	
	return result
end

function Signal.Get(Name: string): ISignal
	return Signals[Name]
end

function Signal.WaitForSignal(Name: string, Timeout: number?): ISignal
	local start = tick()
	Timeout = Timeout or 15
	
	while Signals[Name] == nil do
		task.wait()
		if start then
			if tick() - start > Timeout then
				start = nil
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
	local result: IConnection = setmetatable({}, Connection)
	result.Signal = self
	result.Function = Function
	table.insert(self.Connections, result)
	return result
end

-- Destroys current signal and clears all variables.
function Signal:Destroy() 
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
	end
	self.Connections = nil
	self.Name = nil
	setmetatable(self, nil)
end

-- Disconnects connection from a signal.
function Connection:Disconnect()
	self.Signal.Connections[self] = nil
	self.Function = nil
	self.Signal = nil
	setmetatable(self, nil)
end



return Signal
