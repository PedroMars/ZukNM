local API = require("api")

local ZukLogger = {
    levels = {
        DEBUG = "DEBUG",
        INFO = "INFO",
        WARN = "WARN",
        ERROR = "ERROR"
    },
    currentLevel = "INFO",
    includeTimestamp = true,
    debugMode = false
}


function ZukLogger:FormatMessage(level, message)
    local timestamp = ""
    if self.includeTimestamp then
        timestamp = "[" .. os.date("%H:%M:%S") .. "] "
    end
    return timestamp .. "[" .. level .. "] " .. message
end

function ZukLogger:Debug(message)
    if self.currentLevel == self.levels.DEBUG then
        local formattedMessage = self:FormatMessage(self.levels.DEBUG, message)
        print(formattedMessage)
        API.Log(formattedMessage, "debug")
    end
end

function ZukLogger:Info(message)
    if self.currentLevel == self.levels.DEBUG or 
       self.currentLevel == self.levels.INFO then
        local formattedMessage = self:FormatMessage(self.levels.INFO, message)
        print(formattedMessage)
        API.Log(formattedMessage, "info")
    end
end

function ZukLogger:Warn(message)
    if self.currentLevel ~= self.levels.ERROR then
        local formattedMessage = self:FormatMessage(self.levels.WARN, message)
        print(formattedMessage)
        API.Log(formattedMessage, "warn")
    end
end

function ZukLogger:Error(message)
    local formattedMessage = self:FormatMessage(self.levels.ERROR, message)
    print(formattedMessage)
    API.Log(formattedMessage, "error")
end


return ZukLogger