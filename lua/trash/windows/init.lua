local fn = vim.fn
local uv = vim.uv or vim.loop

local ffi = require("ffi")
local shell32 = ffi.load("shell32")
local utils = require("trash.windows.utils")

--- @class Windows
--- @field trash_path string
--- @field sid string
--- @field op ffi.cdata*
local windows = {}

--- Move the file to the trash
--- @param path string target file path
function windows.trash_file(path)
	if not uv.fs_stat(path) then
	    return vim.notify("Not found target file, path: " .. path, vim.log.levels.WARN)
	end

    if not windows.op then
        --- @diagnostic disable
        local op = ffi.new("SHFILEOPSTRUCTW")

        op.wFunc = 3
        op.pTo = nil
        op.fFlags = 0x40 + 0x10
        op.hwnd = nil
        op.hNameMappings = nil
        op.lpszProgressTitle = nil
    
        windows.op = op
    end

    windows.op.pFrom = utils.to_wide(path)
	-- fAnyOperationsAborted = 0

	if shell32.SHFileOperationW(op) ~= 0 then
		vim.notify("Faild to move the file: " .. path, vim.log.levels.WARN)
	end
end

--- @return Windows
function windows.setup()
	local out = fn.systemlist("whoami /user")

	for _, row in pairs(out) do
		local sid = row:match("S%-1%-5%-.+")

		if sid then
			windows.sid = sid
			break
		end
	end

	if windows.sid == nil then
		return vim.notify("Not found a trash, platform: windows", vim.log.levels.WARN)
	end

	--- @diagnostic disable-next-line
	if not ffi._trash_defined then
		ffi.cdef([[
            typedef struct _SHFILEOPSTRUCTW {
                void* hwnd;
                uint32_t wFunc;
                const wchar_t* pFrom;
                const wchar_t* pTo;
                uint16_t fFlags;
                int fAnyOperationsAborted;
                void* hNameMappings;
                const wchar_t* lpszProgressTitle;
            } SHFILEOPSTRUCTW;

            int SHFileOperationW(SHFILEOPSTRUCTW* lpFileOp);
        ]])

		ffi._trash_defined = true
	end

	windows.trash_path = "C:\\$Recycle.Bin\\" .. windows.sid

	return windows
end

return windows
