{CompositeDisposable, BufferedProcess, NotificationManger} = require 'atom'
cp = require 'child_process'
shell = require 'shelljs'

GitWipView = require './git-wip-view'
Metadata = require './metadata'


# Main Module
module.exports = GitWip =

  config: Metadata.config

  activate: (state) ->
    @gitWipView = null
    @modalPanel = null
    @subscriptions = null
    @packageName = require('../package.json').name
    @packagePath = atom.packages.resolvePackagePath(@packageName)
    @binPath = "#{@packagePath}/bin"
    @debugMsgs = Metadata.messages

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register event listener for file saves
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave (event) =>
        if @getConfig('wipOnSave') then @doGitWip(editor.getPath())

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'git-wip:add-file-checkpoint': (event) => @doGitWip(@activeItemPath())
      'git-wip:add-project-checkpoint': (event) => @doGitWip()

  deactivate: ->
    @subscriptions?.dispose()

  serialize: ->

  getConfig: (name) -> atom.config.get("#{@packageName}.#{name}")

  activeItem: -> atom.workspace.getActiveTextEditor()

  activeItemPath: -> @activeItem()?.getPath()

  getRepos: ->
    currProject = atom.project
    repoForCurrentProject = currProject.repositoryForDirectory.bind(currProject)
    mapProjectDirs = currProject.getDirectories().map(repoForCurrentProject)
    Promise.all(mapProjectDirs)

  getWorkingDirectories: (cb) ->
    @getRepos().then (repositories) ->
      workingDirectories =
        repositories.map (repo) ->
          return repo?.repo?.workingDirectory
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
    # If it's empty, assume user wants to WIP the whole repo.
    return true unless path? and @isFilePath(path)

    @debug "validating path: #{path}"
    @debug "isFilePath: #{@isFilePath(path)}"

    re = new RegExp(directory)
    if re.test(path)
      @debug("#{path} #{@debugMsgs.pathFoundInRepo}")
      return true
    else
      if atom.config.get "#{@packageName}.warn"
        @notifyUser(@debugMsgs.fileNotFoundInRepo, "error")
      @debug "#{path} #{@debugMsgs.pathInvalidForRepo}"
      return false

  ###*
   * Create a new WIP checkpoint.
   * @param  {string} path - Path to a file or directory to save.
   * @return {null}
  ###
  doGitWip: (path) ->
    numReposInProject = atom.project.getRepositories().length
    @debug "numReposInProject: #{numReposInProject}"
    return @errorNoGitRepo() unless numReposInProject isnt 0

    command = "#{@binPath}/git-wip"
    args = ["save"]

    @getWorkingDirectories (directories) =>
      # TODO loop if multiple projects
      cdPath = directory = directories[0]

      if path? and @validatePath(path, directory)
        args.push("'Atom autosave: \"#{path}\"'")
        args.push("--editor")
        args.push("--")
        args.push("\"#{path}\"")
        @debug "Path is VALID. Using command: #{command}"
      else
        args.push("\"Atom autosave\"")
        args.push("--editor")
        args.push("--untracked")
        @debug "Path is INVALID. Using command: #{command}"

      # Build Command
      finalCommand = "#{command} #{args.join(' ')}"
      @debug "finalCommand: #{finalCommand}"

      # Execution
      @debug "Changing directory to #{cdPath}..."
      shell.cd(cdPath)
      pwd = shell.pwd()
      @debug "Now in directory: #{pwd}"

      if pwd is directory
        @debug "Successfuly change directories. Executing: #{finalCommand}"
        child = shell.exec finalCommand, {async: true}, (code, output) =>
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
        throw new Error(Metadata.messages.binaryNotFound)
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
      atom.notifications.addInfo "GIT WIP: #{message}"

  debugLog: []
  getDebugLog: -> console.log @debugLog.join("\n")
