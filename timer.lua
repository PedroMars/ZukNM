API = require("api")
---@class Timer
---@field timers table<string, number>
---@field tasks table<string, {executeTime: number, func: function}>
local Timer = {
  timers = {},
  tasks = {},
}


function Timer:shouldRun(name)
  if not self.timers[name] then
    return true
  end
  return os.clock() >= self.timers[name]
end


function Timer:randomThreadedSleep(name, minMs, maxMs)
  local randomDuration = math.random(minMs, maxMs)
  return self:createSleep(name, randomDuration)
end

function Timer:createSleep(name, duration)
  duration = duration / 1000
  local time = os.clock() + duration
  self.timers[name] = time
  return time
end



return Timer
