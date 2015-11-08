
GitWipView = require './git-wip-view'
{CompositeDisposable, BufferedProcess, NotificationManger} = require 'atom'
cp = require 'child_process'
shell = require 'shelljs'

# Main Module
module.exports = GitWip =

  # Config
  config:
    wipOnSave:
      type: 'boolean'
      default: true
      title: 'WIP on each file save'
      description: 'Creates a WIP checkpoint whenever you save a file.'
    notify:
      type: 'boolean'
      default: true
      title: 'Notify'
      description: 'Display a notification every time a WIP checkpoint is created'

  activate: (state) ->
    @gitWipView = null
    @modalPanel = null
    @subscriptions = null
    @packageName = require('../package.json').name
    @packagePath = atom.packages.resolvePackagePath(@packageName)
    @binPath = "#{@packagePath}/bin"
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable


    # Register event listener for file saves
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave (event) =>
        if atom.config.get "#{@packageName}.wipOnSave"
          @doGitWip(editor.getPath())

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'git-wip:add-file-checkpoint': (event) =>

        @doGitWip @activeItemPath()
      'git-wip:add-project-checkpoint': (event) =>
        @doGitWip()

  deactivate: ->
    @subscriptions?.dispose()

  serialize: ->

  activeItem: -> atom.workspace.getActiveTextEditor()

  activeItemPath: -> @activeItem()?.getPath()

  getRepos: ->
    Promise.all(atom.project.getDirectories().map(atom.project.repositoryForDirectory.bind(atom.project)))

  getWorkingDirectories: (cb) ->
    @getRepos().then (repositories) ->
      workingDirectories = repositories.map (repo) -> return repo.repo.workingDirectory
      cb.call(null, workingDirectories)



  isFilePath: (path) ->
    stringAfterLastSlash = path.split("/")[-1..]
    if /\./.test stringAfterLastSlash then true else false

  ###*
   * Ensure the path being saved is part of the repository.
   * @param  {string}  path - Path which is being saved.
   * @return {boolean}
  ###
  validatePath: (path, directory) ->
    @debug "validating path: #{path}"
    @debug "isFilePath: #{@isFilePath(path)}"
    if path? and @isFilePath(path)
      re = new RegExp directory
      unless re.test path
        messageFileNotInRepo = "The file that was saved is not part of this
          project's git repository. Therefore no WIP checkpoint was saved.
          If you're sure this file is part of the current project's repo,
          make sure you don't have multiple top-level folders open."
        @notifyUser messageFileNotInRepo, "error"
        @debug "File #{path} not part of repo - aborting..."
        return false
      else
        @debug "File #{path} found in repo - continuing.."
        return true
    else
      @debug "Path is directory - will WIP entire project.."
      return true

  ###*
   * Create a new WIP checkpoint.
   * @param  {string} path - Path to a file or directory to save.
   * @return {null}
  ###
  doGitWip: (path) ->
    numReposInProject = atom.project.getRepositories().length
    @debug "numReposInProject: #{numReposInProject}"
    return @errorNoGitRepo() unless numReposInProject isnt 0

    command = "#{@binPath}/git-wip save"

    @getWorkingDirectories (directories) =>
      # TODO loop if multiple projects
      cdPath = directory = directories[0]

      if @validatePath(path, directory)
        command += " \"Atom autosave: #{path}\" --editor -- #{path}"
        @debug "Path is VALID. Using command: #{command}"
      else
        command+= " \"Atom autosave\" --editor --untracked "
        @debug "Path is INVALID. Using command: #{command}"

      @debug "Changing directory to #{cdPath}..."
      shell.cd(cdPath)
      pwd = shell.pwd()
      @debug "Now in directory: #{pwd}"
      if pwd is directory
        @debug "Successfuly change directories. Executing: #{command}"
        child = shell.exec command, {async: true}, (code, output) =>
          if code is 0 and atom.config.get "#{@packageName}.notify"
            @debug "WIP Successfully Completed!"
            @notifyUser "git WIP checkpoint created!", "success"
          if /error/.test output
            @debug "WIP Failed: #{output}"
            throw new Error "#{output}"
        # child.stdout.on 'data', (data) ->
        #   console.log data
      else
        @debug "WIP Failed! Change directory led to #{pwd}. Expected: #{cdPath}"
        throw new Error "change directory led to #{pwd}"


  errorNoGitRepo: -> @notifyUser "No git repo found!", "error"

  notifyUser: (message, type = "success") ->
    if type is "success"
      atom.notifications.addSuccess message
    if type is "error"
      atom.notifications.addError message
    if type is "fatalError"
      atom.notifications.addFatalError message
    if type is "info"
      atom.notifications.addInfo message


  doChecksThenDoWip: (filePath) ->
    command = "which"
    self = this
    stdout = (output) ->
      unless output and /git-wip/.test(output)
        throw new Error('bin git-wip not found: please install from https://github.com/bartman/git-wip and ensure it is in your bin path')
      else
        self.doGitWip(filePath if filePath?)

    exit = (code) -> console.log "`which` exited with #{code}"

    process = new BufferedProcess {command: command, args: ["git-wip"], stdout: stdout, exit: exit}

  # ----------------------------------------------------------------------------
  # Debugging helpers
  #
  # To view debugging info, run the following in console:
  # > gitWip = atom.packages.getActivePackage('git-wip').mainModule
  # > gitWip.getDebugLog()
  debug: (message) ->
    @debugLog.shift() if @debugLog.length > 100
    @debugLog.push("Git Wip: #{message}")
    if atom.config.get('debug')
      atom.notifications.addInfo "Apathy Theme: #{message}"

  debugLog: []
  getDebugLog: -> console.log @debugLog.join("\n")
