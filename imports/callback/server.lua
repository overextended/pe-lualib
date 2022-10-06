local events = {}
local cbEvent = ('__ox_cb_%s')

RegisterNetEvent(cbEvent:format(cache.resource), function(key, ...)
	local cb = events[key]
	return cb and cb(...)
end)

---@param ... any
---@return function
local function tuple(...)
    local co = coroutine.wrap(function(...)
        coroutine.yield()
        while true do
            coroutine.yield(...)
        end
    end)
    co(...)
    return co
end

---@param _ any
---@param event string
---@param playerId number
---@param cb function|false
---@param ... any
---@return unknown?
local function triggerClientCallback(_, event, playerId, cb, ...)
	local key

	repeat
		key = ('%s:%s:%s'):format(event, math.random(0, 100000), playerId)
	until not events[key]

	TriggerClientEvent(cbEvent:format(event), playerId, cache.resource, key, ...)

	---@type promise | false
	local promise = not cb and promise.new()

	events[key] = function(...)
		events[key] = nil
		if promise then
			return promise:resolve(select('#', ...) ~= 0 and tuple(...) or tuple({}))
		end

		return cb and cb(select('#', ...) ~= 0 and ... or {})
	end

	if promise then
		---@type function
		local retData = Citizen.Await(promise)
		return retData()
	end
end

---@overload fun(event: string, playerId: number, cb: function, ...)
lib.callback = setmetatable({}, {
	__call = triggerClientCallback
})

---@param event string
---@param playerId number
--- Sends an event to a client and halts the current thread until a response is returned.
function lib.callback.await(event, playerId, ...)
	return triggerClientCallback(nil, event, playerId, false, ...)
end

local function callbackResponse(success, result, ...)
	if not success then
		if result then
			return print(('^1SCRIPT ERROR: %s^0\n%s'):format(result , Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
		end

		return false
	end

	return tuple(result, ...)()
end

local pcall = pcall

---@param name string
---@param cb function
--- Registers an event handler and callback function to respond to client requests.
function lib.callback.register(name, cb)
	RegisterNetEvent(cbEvent:format(name), function(resource, key, ...)
		TriggerClientEvent(cbEvent:format(resource), source, key, callbackResponse(pcall(cb, source, ...)))
	end)
end

return lib.callback