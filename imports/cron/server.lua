lib.cron = {}

---@alias Date { year: number, month: number, day: number, hour: number, min: number, sec: number, wday: number, yday: number, isdst: boolean }
---@type Date
local currentDate = {}

setmetatable(currentDate, {
    __index = function(self, index)
        local newDate = os.date('*t') --[[@as Date]]
        for k, v in pairs(newDate) do
            self[k] = v
        end
        SetTimeout(1000, function() table.wipe(self) end)
        return self[index]
    end
})

---@class OxTaskProperties
---@field minute? number|string|function
---@field hour? number|string|function
---@field day? number|string|function
---@field month? number|string|function
---@field year? number|string|function
---@field weekday? number|string|function
---@field job fun(task: OxTask, date: osdate)
---@field isActive boolean
---@field id number
---@field debug? boolean
---@field lastRun? number
---@field allowExpiredTasks? boolean

---@class OxTask : OxTaskProperties
---@field expression string
---@field private scheduleTask fun(self: OxTask): boolean?
local OxTask = {}
OxTask.__index = OxTask

local validRanges = {
    min = { min = 0, max = 59 },
    hour = { min = 0, max = 23 },
    day = { min = 1, max = 31 },
    month = { min = 1, max = 12 },
    wday = { min = 0, max = 7 },
}

local maxUnits = {
    min = 60,
    hour = 24,
    wday = 7,
    day = 31,
    month = 12,
}

local weekdayMap = {
    sun = 1,
    mon = 2,
    tue = 3,
    wed = 4,
    thu = 5,
    fri = 6,
    sat = 7,
}

local monthMap = {
    jan = 1, feb = 2, mar = 3, apr = 4,
    may = 5, jun = 6, jul = 7, aug = 8,
    sep = 9, oct = 10, nov = 11, dec = 12
}

---Returns the last day of the specified month
---@param month number
---@param year? number
---@return number
local function getMaxDaysInMonth(month, year)
    return os.date('*t', os.time({ year = year or currentDate.year, month = month + 1, day = -1 })).day --[[@as number]]
end

---@param value string|number
---@param unit string
---@return boolean
local function isValueInRange(value, unit)
    local range = validRanges[unit]
    if not range then return true end
    return value >= range.min and value <= range.max
end

---@param value string
---@param unit string
---@return number|string|function|nil
local function parseCron(value, unit)
    if not value or value == '*' then return end

    if unit == 'day' and value:lower() == 'l' then
        return function()
            return getMaxDaysInMonth(currentDate.month, currentDate.year)
        end
    end

    local num = tonumber(value)
    if num then
        if not isValueInRange(num, unit) then
            error(("^1invalid cron expression. '%s' is out of range for %s^0"):format(value, unit), 3)
        end
        return num
    end

    if unit == 'wday' then
        local start, stop = value:match('(%a+)-(%a+)')
        if start and stop then
            start = weekdayMap[start:lower()]
            stop = weekdayMap[stop:lower()]
            if start and stop then
                if stop < start then stop = stop + 7 end
                return ('%d-%d'):format(start, stop)
            end
        end
        local day = weekdayMap[value:lower()]
        if day then return day end
    end

    if unit == 'month' then
        local months = {}
        for month in value:gmatch('[^,]+') do
            local monthNum = monthMap[month:lower()]
            if monthNum then
                months[#months + 1] = tostring(monthNum)
            end
        end
        if #months > 0 then
            return table.concat(months, ',')
        end
    end

    local stepMatch = value:match('^%*/(%d+)$')
    if stepMatch then
        local step = tonumber(stepMatch)
        if not step or step == 0 then
            error(("^1invalid cron expression. Step value cannot be %s^0"):format(step or 'nil'), 3)
        end
        return value
    end

    local start, stop = value:match('^(%d+)-(%d+)$')
    if start and stop then
        start, stop = tonumber(start), tonumber(stop)
        if not start or not stop or not isValueInRange(start, unit) or not isValueInRange(stop, unit) then
            error(("^1invalid cron expression. Range '%s' is invalid for %s^0"):format(value, unit), 3)
        end
        return value
    end

    local valid = true
    for item in value:gmatch('[^,]+') do
        local num = tonumber(item)
        if not num or not isValueInRange(num, unit) then
            valid = false
            break
        end
    end
    if valid then return value end

    error(("^1invalid cron expression. '%s' is not supported for %s^0"):format(value, unit), 3)
end

---@param value string|number|function|nil
---@param unit string
---@return number|false|nil
local function getTimeUnit(value, unit)
    local currentTime = currentDate[unit]

    if not value then
        return unit == 'min' and currentTime + 1 or currentTime
    end

    if type(value) == 'function' then
        return value()
    end

    local unitMax = maxUnits[unit]

    if type(value) == 'string' then
        local stepValue = string.match(value, '*/(%d+)')

        if stepValue then
            local step = tonumber(stepValue)
            for i = currentTime + 1, unitMax do
                if i % step == 0 then return i end
            end
            return step + unitMax
        end

        local range = string.match(value, '%d+-%d+')
        if range then
            local min, max = string.strsplit('-', range)
            min, max = tonumber(min, 10), tonumber(max, 10)

            if unit == 'min' then
                if currentTime >= max then
                    return min + unitMax
                end
            elseif currentTime > max then
                return min + unitMax
            end

            return currentTime < min and min or currentTime
        end

        local list = string.match(value, '%d+,%d+')
        if list then
            local values = {}
            for listValue in string.gmatch(value, '%d+') do
                values[#values + 1] = tonumber(listValue)
            end
            table.sort(values)

            for i = 1, #values do
                local listValue = values[i]
                if unit == 'min' then
                    if currentTime < listValue then
                        return listValue
                    end
                elseif currentTime <= listValue then
                    return listValue
                end
            end

            return values[1] + unitMax
        end

        return false
    end

    if unit == 'min' then
        return value <= currentTime and value + unitMax or value --[[@as number]]
    end

    return value < currentTime and value + unitMax or value --[[@as number]]
end

---@return number?
function OxTask:getNextTime()
    if not self.isActive then return end

    local day = getTimeUnit(self.day, 'day')

    if day == 0 then
        day = getMaxDaysInMonth(currentDate.month)
    end

    if day ~= currentDate.day then return end

    local month = getTimeUnit(self.month, 'month')
    if month ~= currentDate.month then return end

    local weekday = getTimeUnit(self.weekday, 'wday')
    if weekday and weekday ~= currentDate.wday then return end

    local minute = getTimeUnit(self.minute, 'min')
    if not minute then return end

    local hour = getTimeUnit(self.hour, 'hour')
    if not hour then return end

    if minute >= maxUnits.min then
        if not self.hour then
            hour += math.floor(minute / maxUnits.min)
        end
        minute = minute % maxUnits.min
    end

    if hour >= maxUnits.hour and day then
        if not self.day then
            day += math.floor(hour / maxUnits.hour)
        end
        hour = hour % maxUnits.hour
    end

    local nextTime = os.time({
        min = minute,
        hour = hour,
        day = day or currentDate.day,
        month = month or currentDate.month,
        year = currentDate.year,
    })

    if self.lastRun and nextTime - self.lastRun < 60 then
        if self.debug then
            print(('Preventing duplicate execution of task %s - Last run: %s, Next scheduled: %s'):format(
                self.id,
                os.date('%c', self.lastRun),
                os.date('%c', nextTime)
            ))
        end
        return
    end

    return nextTime
end

---@return number
function OxTask:getAbsoluteNextTime()
    local minute = getTimeUnit(self.minute, 'min')
    local hour = getTimeUnit(self.hour, 'hour')
    local day = getTimeUnit(self.day, 'day')
    local month = getTimeUnit(self.month, 'month')
    local year = getTimeUnit(self.year, 'year')

    if self.day then
        if currentDate.hour < hour or (currentDate.hour == hour and currentDate.min < minute) then
            day = day - 1
            if day < 1 then
                day = getMaxDaysInMonth(currentDate.month)
            end
        end

        if currentDate.hour > hour or (currentDate.hour == hour and currentDate.min >= minute) then
            day = day + 1
            if day > getMaxDaysInMonth(currentDate.month) or day == 1 then
                day = 1
                month = month + 1
            end
        end
    end

    ---@diagnostic disable-next-line: assign-type-mismatch
    if os.time({ year = year, month = month, day = day, hour = hour, min = minute }) < os.time() then
        year = year and year + 1 or currentDate.year + 1
    end

    return os.time({
        min = minute < 60 and minute or 0,
        hour = hour < 24 and hour or 0,
        day = day or currentDate.day,
        month = month or currentDate.month,
        year = year or currentDate.year,
    })
end

function OxTask:getTimeAsString(timestamp)
    return os.date('%A %H:%M, %d %B %Y', timestamp or self:getAbsoluteNextTime())
end

---@type OxTask[]
local tasks = {}

function OxTask:scheduleTask()
    local runAt = self:getNextTime()

    if not runAt then
        return self:stop('getNextTime returned no value')
    end

    local currentTime = os.time()
    local sleep = runAt - currentTime

    if sleep < 0 then
        if self.allowExpiredTasks then
            if self.debug then
                print(('Task %s is slightly overdue by %d seconds, but will execute due to allowExpiredTasks'):format(self.id, -sleep))
            end
            sleep = 1 -- hacky way to force the task to run
        else
            return self:stop(self.debug and ('scheduled time expired %s seconds ago'):format(-sleep))
        end
    end

    local timeAsString = self:getTimeAsString(runAt)

    if self.debug then
        print(('(%s) task %s will run in %d seconds (%0.2f minutes / %0.2f hours)'):format(timeAsString, self.id, sleep,
            sleep / 60,
            sleep / 60 / 60))
    end

    if sleep > 0 then
        Wait(sleep * 1000)
    else
        Wait(1000)
        return true
    end

    if self.isActive then
        if self.debug then
            print(('(%s) running task %s'):format(timeAsString, self.id))
        end

        Citizen.CreateThreadNow(function()
            self:job(currentDate)
            self.lastRun = os.time()
        end)

        return true
    end
end

function OxTask:run()
    if self.isActive then return end

    self.isActive = true

    CreateThread(function()
        while self:scheduleTask() do end
    end)
end

function OxTask:stop(msg)
    self.isActive = false

    if self.debug then
        if msg then
            return print(('stopping task %s (%s)'):format(self.id, msg))
        end

        print(('stopping task %s'):format(self.id))
    end
end

---@param expression string A cron expression such as `* * * * *` representing minute, hour, day, month, and day of the week.
---@param job fun(task: OxTask, date: osdate)
---@param options? { debug?: boolean, allowExpiredTasks?: boolean }
---Creates a new [cronjob](https://en.wikipedia.org/wiki/Cron), scheduling a task to run at fixed times or intervals.
---Supports numbers, any value `*`, lists `1,2,3`, ranges `1-3`, and steps `*/4`.
---Day of the week is a range of `1-7` starting from Sunday and allows short-names (i.e. sun, mon, tue).
function lib.cron.new(expression, job, options)
    if not job or type(job) ~= 'function' then
        error(("expected job to have type 'function' (received %s)"):format(type(job)))
    end

    local minute, hour, day, month, weekday = string.strsplit(' ', string.lower(expression))
    ---@type OxTask
    local task = setmetatable(options or {}, OxTask)

    task.expression = expression
    task.minute = parseCron(minute, 'min')
    task.hour = parseCron(hour, 'hour')
    task.day = parseCron(day, 'day')
    task.month = parseCron(month, 'month')
    task.weekday = parseCron(weekday, 'wday')
    task.id = #tasks + 1
    task.job = job
    task.lastRun = nil
    tasks[task.id] = task
    task:run()

    return task
end

-- reschedule any dead tasks on a new day
lib.cron.new('0 0 * * *', function()
    for i = 1, #tasks do
        local task = tasks[i]
        if not task.isActive then
            task:run()
        end
    end
end)

return lib.cron
