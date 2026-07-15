--!nonstrict

local cachedProjects = nil

local function getDbPath()
	local configured = noctalia.getConfig("db_path")
	if type(configured) == "string" and configured ~= "" then
		return noctalia.expandPath(configured)
	end
	return noctalia.expandPath("~/.local/share/zed/db/0-stable/db.sqlite")
end

local function getMaxResults()
	local n = noctalia.getConfig("max_results")
	return (type(n) == "number" and n > 0) and math.floor(n) or 20
end

local function trim(s)
	return s:match("^%s*(.-)%s*$")
end

local function projectName(path)
	return path:match("([^/]+)$") or path
end

local function shellQuote(s)
	return "'" .. s:gsub("'", "'\"'\"'") .. "'"
end

local function loadProjects(onDone)
	local db = getDbPath()
	local limit = getMaxResults()
	local sql = string.format(
		"SELECT DISTINCT paths FROM workspaces WHERE paths IS NOT NULL AND paths != '' AND remote_connection_id IS NULL ORDER BY timestamp DESC LIMIT %d;",
		limit
	)
	local cmd = string.format("sqlite3 -separator '\\n' %s %s 2>/dev/null", shellQuote(db), shellQuote(sql))

	noctalia.runAsync(cmd, function(result)
		local projects = {}
		if result.exitCode == 0 and type(result.stdout) == "string" then
			for line in result.stdout:gmatch("[^\n]+") do
				local path = trim(line)
				if path ~= "" then
					table.insert(projects, path)
				end
			end
		end
		cachedProjects = projects
		onDone(projects)
	end)
end

local function filterProjects(projects, query)
	if query == "" then
		return projects
	end

	local lower = query:lower()
	local results = {}
	for _, path in projects do
		if path:lower():find(lower, 1, true) then
			table.insert(results, path)
		end
	end
	return results
end

local function makeRows(projects)
	local home = noctalia.getenv("HOME") or ""
	local rows = {}
	for _, path in projects do
		local display = (home ~= "" and path:sub(1, #home) == home) and "~" .. path:sub(#home + 1) or path
		table.insert(rows, {
			id = path,
			title = projectName(path),
			subtitle = display,
			icon = "zed",
		})
	end
	return rows
end

local function showResults(query, projects, filter)
	local filtered = filterProjects(projects, filter)
	if #filtered == 0 then
		launcher.setResults(query, {
			{
				id = "",
				title = noctalia.tr("no-projects-found"),
				subtitle = filter ~= "" and noctalia.tr("filter-empty", { filter = filter }) or noctalia.tr("database-empty"),
				glyph = "folder-x",
			},
		})
	else
		launcher.setResults(query, makeRows(filtered))
	end
end

function onQuery(query)
	local filter = trim(query)

	if cachedProjects then
		showResults(query, cachedProjects, filter)
		return
	end

	launcher.setResults(query, {
		{
			id = "",
			title = noctalia.tr("loading"),
			subtitle = noctalia.tr("loading-subtitle"),
			glyph = "loader",
		},
	})

	loadProjects(function(projects)
		showResults(query, projects, filter)
	end)
end

function onActivate(id)
	if id == "" then
		return
	end
	noctalia.runAsync(string.format("nohup zeditor %s &>/dev/null &", shellQuote(id)))
end
