local utils = {}

local ffi = require("ffi")

local byte = string.byte
local char = string.char

local insert = table.insert
local concat = table.concat

local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift

--- @param str string
--- @return ffi.cdata*
function utils.to_wide(str)
	local out = {}
	local i = 1
	local n = #str
	while i <= n do
		local c = byte(str, i)
		local code
		if c < 0x80 then
			code = c
			i = i + 1
		elseif c < 0xE0 then
			code = bor(lshift(band(c, 0x1F), 6), band(byte(str, i + 1), 0x3F))
			i = i + 2
		elseif c < 0xF0 then
			code = bor(lshift(band(c, 0x0F), 12), lshift(band(byte(str, i + 1), 0x3F), 6), band(byte(str, i + 2), 0x3F))
			i = i + 3
		else
			code = bor(
				lshift(band(c, 0x07), 18),
				lshift(band(byte(str, i + 1), 0x3F), 12),
				lshift(band(byte(str, i + 2), 0x3F), 6),
				band(byte(str, i + 3), 0x3F)
			)
			i = i + 4
		end

		if code <= 0xFFFF then
			insert(out, char(band(code, 0xFF), rshift(code, 8)))
		else
			code = code - 0x10000
			local high = 0xD800 + rshift(code, 10)
			local low = 0xDC00 + band(code, 0x3FF)
			insert(out, char(band(high, 0xFF), rshift(high, 8)))
			insert(out, char(band(low, 0xFF), rshift(low, 8)))
		end
	end
	
    insert(out, "\0\0")
	
    return ffi.cast("const wchar_t*", concat(out))
end

return utils
