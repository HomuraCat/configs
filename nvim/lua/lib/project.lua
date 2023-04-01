local class = require('lib/class')
local terminal = require('terminal')

-- Project class
local Project = class()
Project.default_args = {
  host_user = require('lib/core').get_username(),
  host_path = vim.fn.getcwd(),
}

-- {{{ Project api
function Project:init(args)
  args           = vim.tbl_deep_extend('force', Project.default_args, args or {})

  assert(args.name, 'project name cannot be nil')

  self.name      = args.name
  self.host_user = args.host_user
  self.host_path = args.host_path
  self.args      = args
end

-- send a project-scoped notification
function Project:notify(content, type, opts)
  require('utils').notify(string.format('[%s] %s', self.name, content), type, opts)
end

-- add a project-scoped command
function Project:add_command(name, callback, opts, also_custom)
  require('utils').add_command(string.format('[%s] %s', self.name, name), callback, opts, also_custom)
end

-- add project-dap config
function Project:add_dap_config(name, program, args)
  assert(program, 'program argument must not be nil')
  args = args or {}

  self.dap_config = self.dap_config or {}
  self.dap_config[name] = { program = program, args = args }
end

-- }}}

-- RemoteProject class
local RemoteProject = class(Project)
RemoteProject.default_args = {}

-- {{{ RemoteProject api
function RemoteProject:init(args)
  args = vim.tbl_deep_extend('force', RemoteProject.default_args, args or {})
  self.super:init(args) -- init superclass

  assert(args.target, 'target cannot be nil')
  assert(args.target_user, 'target_user cannot be nil')
  assert(args.target_path, 'target_path cannot be nil')

  self.target      = args.target
  self.target_user = args.target_user
  self.target_path = args.target_path
end

-- launch rsync host <-> remote target
function RemoteProject:launch_sync(reverse)
  if reverse then
    terminal.launch_terminal(
      string.format(
        'rsync -aP --exclude "venv" %s@%s:%s/ %s',
        self.target_user,
        self.target,
        self.target_path,
        self.host_path
      ),
      false
    )
  else
    terminal.launch_terminal(
      string.format(
        'watch -n0.5 "rsync -aP --exclude "venv" %s/ %s@%s:%s/"',
        self.host_path,

        self.target_user,
        self.target,
        self.target_path
      ),
      true
    )
  end
end

-- launch ssh session host -> remote target
function RemoteProject:launch_ssh(set_target, path)
  path = (path or self.target_path) .. '/'
  local to_path_cmd = 'cd ' .. path .. ' ; bash --'

  terminal.launch_terminal(
    string.format(
      'ssh -t %s@%s "%s"',
      self.target_user,
      self.target,
      to_path_cmd
    ),
    false,
    (set_target and terminal.set_target) or nil
  )
end

-- launch a procject session: ssh and/or rsync host -> remote
function RemoteProject:launch_project_session(sync)
  local use_rsync = sync or false

  -- make ip updatable
  vim.ui.input({ prompt = "target gcp ip> ", default = self.target }, function(ip)
    if ip == nil then
      self:notify(
        string.format("invalid target ip: %s", self.target),
        "warn",
        { render = "minimal" }
      )
      return
    end

    -- MRU update to project target
    self.target = ip

    -- launch sync in background
    if use_rsync then self:launch_sync(false) end

    -- launch ssh terminal
    self:launch_ssh(true)
    self:notify("project session launched", "info", { render = 'minimal' })
  end)
end

-- }}}

return {
  Project = Project,
  RemoteProject = RemoteProject
}
