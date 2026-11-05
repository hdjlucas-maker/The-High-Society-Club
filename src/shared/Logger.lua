local Logger = {}

local function write(level, category, message)
	local label = typeof(category) == "string" and category or "General"
	local output = string.format("[HSC][%s][%s] %s", level, label, tostring(message))
	if level == "INFO" then
		print(output)
	else
		warn(output)
	end
end

function Logger.Info(category, message)
	write("INFO", category, message)
end

function Logger.Warn(category, message)
	write("WARN", category, message)
end

function Logger.Error(category, message)
	write("ERROR", category, message)
end

return Logger
