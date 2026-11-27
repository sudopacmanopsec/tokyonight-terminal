local M = {}

-- max number of files to remember
M.maxsize = 1000

-- paths matching these patterns are never restored or saved
M.ignore = {
	"COMMIT_EDITMSG$",
	"git%-rebase%-todo$",
}

-- save path: {XDG_STATE_HOME|HOME/.local/state}/vis-cursors
M.path = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/vis-cursors"

local cursors = {} -- path -> pos, as loaded on init
local closed = {} -- paths closed this session, most recent last
local closed_pos = {} -- path -> pos at close (0 = forget)

-- read saved positions, returns map and paths in file order (most recent first)
local function read()
	local pos, order = {}, {}
	local file = io.open(M.path)
	if file == nil then
		return pos, order
	end
	for line in file:lines() do
		local path, p = line:match("^(.+)[,%s](%d+)$")
		if path and not pos[path] then
			pos[path] = tonumber(p)
			order[#order + 1] = path
		end
	end
	file:close()
	return pos, order
end

local function is_ignored(path)
	for _, pattern in ipairs(M.ignore) do
		if path:match(pattern) then
			return true
		end
	end
	return false
end

local function path_of(win)
	local path = win.file and win.file.path
	if path == nil or is_ignored(path) then
		return nil
	end
	return path
end

vis.events.subscribe(vis.events.INIT, function()
	cursors = read()
end)

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	local path = path_of(win)
	local pos = path and cursors[path]
	if pos then
		win.selection.pos = pos
		vis:feedkeys("zz")
	end
end)

vis.events.subscribe(vis.events.WIN_CLOSE, function(win)
	local path = path_of(win)
	if path then
		closed[#closed + 1] = path
		closed_pos[path] = win.selection.pos
	end
end)

vis.events.subscribe(vis.events.QUIT, function()
	if #closed == 0 then
		return
	end

	-- re-read so we don't clobber what other vis instances saved meanwhile
	local saved, order = read()
	local lines, seen = {}, {}
	local function add(path, pos)
		if seen[path] or (M.maxsize and #lines >= M.maxsize) then
			return
		end
		seen[path] = true
		if pos > 0 then -- cursor at start: nothing worth remembering
			lines[#lines + 1] = path .. "," .. pos
		end
	end

	-- this session's files first (most recent on top), then the rest
	for i = #closed, 1, -1 do
		add(closed[i], closed_pos[closed[i]])
	end
	for _, path in ipairs(order) do
		add(path, saved[path])
	end

	-- write to a temp file and rename, so a crash never leaves a half-written file
	local tmp = M.path .. ".tmp"
	local file = io.open(tmp, "w")
	if file == nil then
		-- state dir may not exist yet (e.g. ~/.local/state on macOS)
		local dir = M.path:match("^(.*)/")
		if dir then
			os.execute("mkdir -p '" .. dir:gsub("'", "'\\''") .. "'")
			file = io.open(tmp, "w")
		end
		if file == nil then
			return
		end
	end
	file:write(table.concat(lines, "\n"), "\n")
	file:close()
	os.rename(tmp, M.path)
end)

return M
