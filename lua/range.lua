-- https://github.com/linrongbin16/gitlinker.nvim/blob/master/lua/gitlinker/range.lua
local range = {}

local function is_visual_mode(m)
	return type(m) == "string" and string.upper(m) == "V"
		or string.upper(m) == "CTRL-V"
		or string.upper(m) == "<C-V>"
		or m == "\22"
end

function range.make_range()
	local m = vim.fn.mode()
	local l1 = nil
	local l2 = nil
	if is_visual_mode(m) then
		vim.cmd([[execute "normal! \<ESC>"]])
		l1 = vim.fn.getpos("'<")[2]
		l2 = vim.fn.getpos("'>")[2]
	else
		l1 = vim.fn.getcurpos()[2]
		l2 = l1
	end
	local lstart = math.min(l1, l2)
	local lend = math.max(l1, l2)
	local o = {
		lstart = lstart,
		lend = lend,
	}
	return o
end

return range
