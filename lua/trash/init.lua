--- @class Trash
--- @field path string path to the trash
local trash = {}

--- @type Windows
local windows = require("trash.windows")

local fn = vim.fn
local uv = vim.uv or vim.loop

local is_windows = fn.has("win32") == 1 or fn.has("win64") == 1
local is_mac = fn.has("macunix") == 1

--- Move the file to the trash
--- @param path string target file path
function trash.trash_file(path)
	if is_windows then
		windows.trash_file(path)
	else
		if fn.isdirectory(trash.path) then
			local name = fn.fnamemodify(path, ":t")
			fn.rename(path, trash.path .. "/" .. name)
		else
			vim.notify("Not found a trash path, path: " .. trash.path, vim.log.levels.WARN)
		end
	end
end

--- @class Trash.Config
--- @field path? string path to the trash

--- @param options? Trash.Config
--- @return Trash
function trash.setup(options)
	if options and options.path then
		trash.path = options.path
	else
		if is_windows then
			trash.path = windows.setup().trash_path
		elseif is_mac then
			trash.path = fn.expand("~/.Trash")
		else
			trash.path = fn.expand("~/.local/share/Trash/files")
		end
	end

    return trash
end

return trash
