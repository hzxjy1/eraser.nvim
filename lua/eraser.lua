local range = require("range")
local eraser = {}

local function get_commit(ranges)
	local positions = {}
	local query = [[
  (comment) @comment
]]

	local filetype = vim.bo.filetype
	if vim.tbl_contains({ "javascriptreact", "typescriptreact" }, vim.bo.filetype) then
		filetype = "javascript"
	end

	local success, captures = pcall(function()
		return vim.treesitter.query.parse(filetype, query)
	end)
	if not success then
		return {}
	end
	local tree = vim.treesitter.get_parser():parse()[1]
	for _, node, _ in captures:iter_captures(tree:root(), 0, ranges.lstart - 1, ranges.lend) do
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

local function erase_in_line(position, offset)
	if position == nil then
		return 1
	end
	position.row = position.row - offset

	local line = vim.api.nvim_buf_get_lines(0, position.row - 1, position.row, false)[1]
	local cleaned_line = remove_range(line, position.start_col, position.end_col)
	if cleaned_line:match("^[%s\t]*$") then
		if not eraser.config.retain_blank then -- Delete the whole line
			vim.api.nvim_buf_set_lines(0, position.row - 1, position.row, false, {})
			return 2
		end
		cleaned_line = ""
	end

	cleaned_line = cleaned_line:match("^(.-)%s*$") -- Strip blanks in end of line
	-- print(string.format("%q", cleaned_line))
	vim.api.nvim_buf_set_lines(0, position.row - 1, position.row, false, { cleaned_line })

	return 0
end

local function erase_commit()
	local ranges = range.make_range()
	local lines = get_commit(ranges)
	local offset = 0

	for _, line in pairs(lines) do
		if erase_in_line(line, offset) == 2 then
			offset = offset + 1
		end
	end
end

local function erase_plus()
	local ranges = range.make_range()
	for i = ranges.lstart, ranges.lend do
		local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
		if vim.tbl_contains({ "+", "-" }, line:sub(1, 1)) then
			local modified_line = line:sub(2)
			vim.api.nvim_buf_set_lines(0, i - 1, i, false, { modified_line })
		end
	end
end

local function init()
	vim.api.nvim_create_user_command("EraseCommit", erase_commit, {})
	vim.api.nvim_create_user_command("ErasePlus", erase_plus, {})
end

function eraser.setup(opts)
	eraser.config = opts
	init()
end

return eraser
