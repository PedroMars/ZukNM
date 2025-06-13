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

function ZukLogger:SetLevel(level)
    if self.levels[level] then
        self.currentLevel = level
        self:Info("Log level set to " .. level)
    else
        self:Error("Invalid log level: " .. tostring(level))
    end
end

function ZukLogger:SetDebugMode(enabled)
    self.debugMode = enabled
    if enabled then
        self:SetLevel("DEBUG")
    else
        self:SetLevel("INFO")
    end
    self:Info("Debug mode " .. (enabled and "enabled" or "disabled"))
end

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

function ZukLogger:Clear()
    API.ClearLog()
    self:Info("Log cleared")
end

return ZukLogger