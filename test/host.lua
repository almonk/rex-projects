-- Runs the script's git and folder code inside Rex's own Lua (gopher-lua), which
-- differs from LuaJIT in ways that matter: a gsub call inside a ".." expression
-- followed by :gmatch once panicked it. Run with:  rex do test/host.lua
-- It needs git. It makes and removes a repository in a temporary folder.
local dir = (os.getenv("TMPDIR") or "/tmp") .. "/rex-projects-host-" .. os.time()
local function run(...)
  local r = rex.exec({ ... })
  assert(r and r.ok, "failed: " .. table.concat({ ... }, " "))
  return r
end
run("mkdir", "-p", dir .. "/repo")
run("git", "-C", dir .. "/repo", "init", "-q", "-b", "main")
run("git", "-C", dir .. "/repo", "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "i")
local here = debug and debug.getinfo and debug.getinfo(1, "S").source:match("^@(.*)/test/[^/]+$") or "."
local P = dofile(here .. "/projects.lua").setup{ state_file = dir .. "/state.json", worktrees = dir .. "/wt" }
local I = P._internal

local trees = I.worktrees(dir .. "/repo")
assert(#trees == 1 and trees[1].branch == "main", "one checkout on main")
local wt = I.add_worktree(dir .. "/repo", "feat/x", "main")
assert(wt == dir .. "/wt/repo/feat-x", "worktree folder: " .. tostring(wt))
assert(#I.worktrees(dir .. "/repo") == 2)
local rows = I.checkout_rows(dir .. "/repo")
assert(rows[1].title == "Current checkout" and #rows == 3, "rows: " .. #rows)
assert(#I.subfolders(dir) >= 2)
assert(I.base_rows(dir .. "/repo")[1].id == "main")
I.load_state().projects[1] = dir .. "/repo"; I.save_state(); I.reset()
assert(I.load_state().projects[1] == dir .. "/repo", "state round trip")
run("rm", "-rf", dir)
return "host ok"
