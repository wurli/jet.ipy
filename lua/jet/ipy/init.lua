local M = {}

---@class jet.ipy.Config
local config = {
	---If `true` (the default), a warning notification will be shown when
	---opening a kernel without a virtual environment.
	check_for_venv = true,
	---Whether to prioritise kernels which live in a virtual environment
	prioritise_venv = true,
	---Ascend the tree until we hit one of these. Full list at
	---https://github.com/tree-sitter/tree-sitter-python/blob/master/grammar.js
	---@type string[]
	top_level_nodes = {
		"assert_statement",
		"class_definition",
		"decorated_definition",
		"delete_statement",
		"exec_statement",
		"expression_statement",
		"for_statement",
		"function_definition",
		"future_import_statement",
		"global_statement",
		"if_statement",
		"import_from_statement",
		"import_statement",
		"match_statement",
		"nonlocal_statement",
		"print_statement",
		"try_statement",
		"type_alias_statement",
		"while_statement",
		"with_statement",
	},
}

---@param pos jet.send.Pos
---@return jet.send.Range?
local get_python_expr = function(pos)
	local ok, node = pcall(vim.treesitter.get_node, {
		bufnr = pos.buf,
		pos = { pos.row, pos.col },
		ignore_injections = false,
	})
	if not ok or not node then
		return
	end

	local id = node:id()

	local n_iterations = 0
	while true do
		if n_iterations > 100 then
			print("Quitting: exceeded 100 iterations when ascending treesitter tree")
			return
		end
		if vim.list_contains(config.top_level_nodes, node:type()) then
			break
		end
		node = node:parent()
		if not node then
			return
		end
		local parent_id = node:id()
		n_iterations = n_iterations + 1
		if id == parent_id then
			return
		end
		id = parent_id
	end

	local start_row, start_col, end_row, end_col = node:range(false)

	return require("jet.core.send.range").new({
		buf = pos.buf,
		start_row = start_row,
		start_col = start_col,
		end_row = end_row,
		end_col = end_col,
	})
end

local setup_venv_cmd = function()
	vim.api.nvim_create_user_command("IpyVenv", function(opts)
		local venv = opts.fargs[1] or vim.fs.find(".venv", { type = "directory" })[1]
		if venv then
			vim.env.VIRTUAL_ENV = venv
			local venv_bin = vim.fs.joinpath(venv, "bin")
			if vim.uv.fs_stat(venv_bin) then
				vim.env.PATH = venv_bin .. ":" .. vim.env.PATH
				return
			end
		end
		vim.notify("Virtual environment not found", vim.log.levels.ERROR)
	end, { nargs = "?", complete = "dir" })
end

local did_setup = false

---@param opts? Partial<jet.ipy.Config>
M.setup = function(opts)
	opts = opts or {}

	if did_setup then
		return
	end
	did_setup = true

	setup_venv_cmd()

	local jet = require("jet")
	assert(jet.did_setup(), 'jet.nvim has not done setup; run `require("jet").setup({})` before loading jet.ipy')

	config = vim.tbl_deep_extend("force", config, opts)

	jet.filetype.python = jet.filetype.python or {}
	jet.filetype.python.get_expr = get_python_expr

	if config.prioritise_venv then
		jet.hooks.on_kernel_init.prioritise_ipy_venv = function(k)
			if k.spec_path:match("%.venv/") then
				k.priority = 200
			end
		end
	end
	if config.check_for_venv then
		jet.hooks.on_lua_client_start.warn_not_venv = function(k)
			if k.spec.display_name:lower():match("python") and not k.spec_path:match("%.venv/") then
				vim.notify(
					table.concat({
						"Warning: starting Python kernel without a virtual environment",
						"- Hint: use :IpyVenv to activate a virtual environment if one exists",
					}, "\n"),
					vim.log.levels.WARN
				)
			end
		end
	end
	jet.hooks.on_kernel_init.set_python_ft = function(k)
		if k.spec.display_name:lower():match("python") then
			k.filetype = "python"
		end
	end
end

return M
