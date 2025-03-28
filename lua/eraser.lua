local eraser = {}

--https://github.com/linrongbin16/gitlinker.nvim/blob/master/lua/gitlinker/range.lua#L5
local function is_visual_mode(m)
	return type(m) == "string" and string.upper(m) == "V"
		or string.upper(m) == "CTRL-V"
		or string.upper(m) == "<C-V>"
		or m == "\22"
end

-- https://github.com/linrongbin16/gitlinker.nvim/blob/master/lua/gitlinker/range.lua#L14
local function make_range()
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

local function erase_plus(range_table)
	for i = range_table.lstart, range_table.lend do
		local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
		if line:sub(1, 1) == "+" then
			local modified_line = line:sub(2)
			vim.api.nvim_buf_set_lines(0, i - 1, i, false, { modified_line })
		end
	end
end

local function get_commit(range_table)
	local positions = {}
	local query = [[
  (comment) @comment
]]
	local captures = vim.treesitter.query.parse(vim.bo.filetype, query)
	local tree = vim.treesitter.get_parser():parse()[1]
	for _, node, _ in captures:iter_captures(tree:root(), 0, range_table.lstart - 1, range_table.lend) do
		local start_row, start_col, _, end_col = node:range()
		local position = {
			row = start_row + 1,
			start_col = start_col,
			end_col = end_col,
		}
		table.insert(positions, position)
	end
	return positions
end

local function remove_range(str, start_col, end_col)
	if start_col == 0 and end_col == #str then
		return ""
	end

	if start_col < 1 or end_col > #str or start_col > end_col then
		return str
	end

	local before = str:sub(1, start_col)
	local after = str:sub(end_col + 1)

	return before .. after
end

local function erase_in_line(position)
	if position == nil then
		return
	end
	local line = vim.api.nvim_buf_get_lines(0, position.row - 1, position.row, false)[1]
	local cleaned_line = remove_range(line, position.start_col, position.end_col)
	if cleaned_line:match("^[\t%s]*$") then
		cleaned_line = ""
	end
	vim.api.nvim_buf_set_lines(0, position.row - 1, position.row, false, { cleaned_line })
end

function eraser.init()
	vim.api.nvim_create_user_command("EraseCommit", function()
		local range = make_range()
		local lines = get_commit(range)
		for _, line in pairs(lines) do
			erase_in_line(line)
		end
	end, {})

	vim.api.nvim_create_user_command("ErasePlus", function()
		local range = make_range()
		erase_plus(range)
	end, {})
end

function eraser.setup()
	eraser.init()
end

return eraser
