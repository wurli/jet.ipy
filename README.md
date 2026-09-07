# jet.ipy

An extension for [jet.nvim](https://github.com/wurli/jet.nvim) adding better
support for ipython/ipykernel.

## Features

- Better 'expression' resolution (e.g. for intelligently selecting code around
  the cursor to send to the repl). Note that you still need to configure 'send
  to repl' and/or 'get current expr' keymaps. See
  https://github.com/wurli/jet.nvim#installation for more info.

- Prioritisation of kernels which belong to a virtual environment

## Installation

``` lua
vim.pack.add("https://github.com/wurli/jet.ipy")
require("jet.ipy").setup()
```

## Default Config

``` lua
---@class jet.ipy.Config
local config = {
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
```
