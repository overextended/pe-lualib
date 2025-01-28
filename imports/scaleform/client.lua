---@class renderTargetTable
---@field name string
---@field model string|number

---@class detailsTable
---@field name string
---@field fullScreen? boolean
---@field x? number
---@field y? number
---@field width? number
---@field height? number
---@field renderTarget? renderTargetTable

---@class Scaleform : OxClass
---@field scaleform number
---@field draw boolean
---@field target number
---@field targetName string
---@field handle number
---@field fullScreen boolean
lib.scaleform = lib.class('Scaleform')

--- Converts the arguments into data types usable by scaleform
---@param argsTable (number | string | boolean)[]
local function convertArgs(argsTable)
    for i = 1, #argsTable do
        local arg = argsTable[i]
        local argType = type(arg)

        if argType == 'string' then
            ScaleformMovieMethodAddParamPlayerNameString(arg)
        elseif argType == 'number' then
            if math.type(arg) == 'integer' then
                ScaleformMovieMethodAddParamInt(arg)
            else
                ScaleformMovieMethodAddParamFloat(arg)
            end
        elseif argType == 'boolean' then
            ScaleformMovieMethodAddParamBool(arg)
        else
            error(('Unsupported Parameter type [%s]'):format(argType))
        end
    end
end

---@param expectedType 'boolean' | 'integer' | 'string'
---@return boolean | integer | string
local function retrieveReturnValue(expectedType)
    local result = EndScaleformMovieMethodReturnValue()

    lib.waitFor(function()
        if IsScaleformMovieMethodReturnValueReady(result) then
            return true
        end
    end, "Failed to retrieve return value", 1000)

    if expectedType == "integer" then
        return GetScaleformMovieMethodReturnValueInt(result)
    elseif expectedType == "boolean" then
        return GetScaleformMovieMethodReturnValueBool(result)
    else
        return GetScaleformMovieMethodReturnValueString(result)
    end
end

---@param details detailsTable | string
---@return nil
function lib.scaleform:constructor(details)
    details = type(details) == 'table' and details or { name = details }

    local scaleform = lib.requestScaleformMovie(details.name)

    self.sfHandle = scaleform
    self.private.isDrawing = false

    self.fullScreen = details.fullScreen or false
    self.x = details.x or 0
    self.y = details.y or 0
    self.width = details.width or 0
    self.height = details.height or 0

    if details.renderTarget then
        self:setRenderTarget(details.renderTarget.name, details.renderTarget.model)
    end
end

---@param name string
---@param args? (number | string | boolean)[]
---@param returnValue? string
---@return any
function lib.scaleform:callMethod(name, args, returnValue)
    if not self.sfHandle then
        return error("attempted to call method with invalid scaleform handle")
    end

    BeginScaleformMovieMethod(self.sfHandle, name)

    if args and type(args) == 'table' then
        convertArgs(args)
    end

    if returnValue then
        return retrieveReturnValue(returnValue)
    end

    EndScaleformMovieMethod()
end

---@param isFullscreen boolean
---@return nil
function lib.scaleform:setFullScreen(isFullscreen)
    self.fullScreen = isFullscreen
end

---@param x number
---@param y number
---@param width number
---@param height number
---@return nil
function lib.scaleform:setProperties(x, y, width, height)
    if self.fullScreen then
        lib.print.info('Cannot set properties when full screen is enabled')
        return
    end

    self.x = x
    self.y = y
    self.width = width
    self.height = height
end

---@param name string
---@param model string|number
---@return nil
function lib.scaleform:setRenderTarget(name, model)
    if self.target then
        ReleaseNamedRendertarget(self.targetName)
    end

    if type(model) == 'string' then
        model = joaat(model)
    end

    if not IsNamedRendertargetRegistered(name) then
        RegisterNamedRendertarget(name, false)

        if not IsNamedRendertargetLinked(model) then
            LinkNamedRendertarget(model)
        end

        self.target = GetNamedRendertargetRenderId(name)
        self.targetName = name
    end
end

---@return nil
function lib.scaleform:startDrawing()
    if self.isDrawing then
        return
    end

    self.isDrawing = true
    CreateThread(function()
        while self.isDrawing do
            if self.target then
                SetTextRenderId(self.target)
                SetScriptGfxDrawOrder(4)
                SetScriptGfxDrawBehindPausemenu(true)
                SetScaleformFitRendertarget(self.sfHandle, true)
            end

            if self.fullScreen then
                DrawScaleformMovieFullscreen(self.sfHandle, 255, 255, 255, 255, 0)
            else
                if not self.x or not self.y or not self.width or not self.height then
                    error('attempted to draw scaleform without setting properties')
                else
                    DrawScaleformMovie(self.sfHandle, self.x, self.y, self.width, self.height, 255, 255, 255, 255, 0)
                end
            end

            if self.target then
                SetTextRenderId(1)
            end

            Wait(0)
        end
    end)
end

---@return nil
function lib.scaleform:stopDrawing()
    if not self.isDrawing then
        return
    end
    self.isDrawing = false
end

---@return nil
function lib.scaleform:dispose()
    if self.sfHandle then
        SetScaleformMovieAsNoLongerNeeded(self.sfHandle)
    end

    if self.target then
        ReleaseNamedRendertarget(self.targetName)
    end

    self.sfHandle = nil
    self.target = nil
    self.isDrawing = false
end

---@return Scaleform
return lib.scaleform
