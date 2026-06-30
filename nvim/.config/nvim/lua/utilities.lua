local utilities = {}

function utilities.get_current_buffer_path()
  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if bufname == "" then
    return "[No Name]"
  else
    return vim.fn.fnamemodify(bufname, ":p")
  end
end

function utilities.folder_exists(path)
  local expanded_path = vim.fn.expand(path)
  local stat = vim.loop.fs_stat(expanded_path)
  return stat and stat.type == "directory" or false
end

function utilities.is_work_laptop()
  local test_path = "C:\\Projects\\Confluence\\Unity"
  return utilities.folder_exists(test_path)
end

function utilities.get_visual_selection()
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local start_col = start_pos[3]
  local end_col = end_pos[3]

  if #lines == 1 then
    lines[1] = lines[1]:sub(start_col, end_col)
  else
    lines[1] = lines[1]:sub(start_col)
    lines[#lines] = lines[#lines]:sub(1, end_col)
  end

  return table.concat(lines, "\n")
end

function utilities.replace_visual_selection(replacement)
  local start_pos = vim.fn.getpos "'<"
  local end_pos = vim.fn.getpos "'>"
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  local new_lines = {}

  for i, line in ipairs(lines) do
    local start_col = i == 1 and start_pos[3] or 1
    local end_col = i == #lines and end_pos[3] or -1
    local prefix = line:sub(1, start_col - 1)
    local suffix = end_col == -1 and "" or line:sub(end_col + 1)
    table.insert(new_lines, prefix .. replacement .. suffix)
  end

  vim.api.nvim_buf_set_lines(0, start_pos[2] - 1, end_pos[2], false, new_lines)
end

function utilities.sort_tailwind_classes(text)
  -- Split the string into individual classes
  local classes = vim.split(text, " ")
  print(classes)
  -- Define the order of prefixes
  local prefix_order = { "^sm:.*", "^md:.*", "^lg:.*" }

  -- Sort the classes based on the prefix order
  table.sort(classes, function(a, b)
    local a_index = 0
    local b_index = 0

    for i, prefix in ipairs(prefix_order) do
      if string.match(a, prefix) then
        a_index = i
      end
    end
    for i, prefix in ipairs(prefix_order) do
      if string.match(b, prefix) then
        b_index = i
      end
    end

    return a_index < b_index
  end)
  -- Join the sorted classes back into a string
  local sorted_text = table.concat(classes, " ")
  -- Replace the current line with the sorted text
  -- vim.api.nvim_put({ sorted_text }, "l", true, true)
  -- print(sorted_text)
  -- vim.fn.setreg("+", sorted_text)
  return sorted_text
end

function utilities.not_starts_with(str, prefixes)
  for _, prefix in ipairs(prefixes) do
    if str:find("^" .. prefix) then
      return false
    end
  end
  return true
end

function utilities.sort_selected_text()
  local text = utilities.get_visual_selection()
  local sortedText = utilities.sort_tailwind_classes(text)
  utilities.replace_visual_selection(sortedText)
end

function utilities.convert_windows_to_linux_path(path)
  if not path then
    return nil
  end

  -- Replace "C:" with "/mnt/c"
  local result = string.gsub(path, "C:", "/mnt/c")

  -- Replace all backslashes with forward slashes
  result = string.gsub(result, "\\", "/")

  return result
end

function utilities.add_trailing_slash_ifneeded(str)
  if str == nil or str == "" then
    return "/"
  end

  -- Check if the last character is already a slash
  if string.sub(str, -1) ~= "/" then
    return str .. "/"
  else
    return str
  end
end

function utilities.FzfGrepFilesByType()
  local fzf = require("fzf-lua")
  vim.ui.input({ prompt = 'File ext: ' }, function(input)
    if input == nil or input == '' then
      return
    end

    -- Clean up the input (remove leading dot if present)
    local extension = input:gsub("^%.", "")

    fzf.live_grep({
      cmd = "fd --type f --extension " .. input,
      prompt = "Files(" .. extension .. ") ❯ ",
      input_prompt = "Search in ." .. extension .. " files: ",
    })
  end)
end

function utilities.FzfGrepLinesByType()
  local fzf = require("fzf-lua")
  vim.ui.input({ prompt = 'File ext: ' }, function(input)
    if input == nil or input == '' then
      return
    end

    -- Clean up the input (remove leading dot if present)
    local extension = input:gsub("^%.", "")

    local glob_pattern = '*.' .. extension
    local escaped_glob = vim.fn.shellescape('--glob=' .. glob_pattern)

    fzf.live_grep({
      cmd = 'rg --glob-case-insensitive --column --line-number --no-heading --color=always --smart-case ' .. escaped_glob,
      prompt = "Grep(" .. extension .. ") ❯ ",
      input_prompt = "Search in ." .. extension .. " files: ",
    })
  end)
end

vim.g.utilities = utilities

return utilities
