
GitWipView = require './git-wip-view'
{CompositeDisposable, BufferedProcess, NotificationManger} = require 'atom'
ps = require 'child_process'
shell = require 'shelljs'
module.exports = GitWip =
  gitWipView: null
  modalPanel: null
  subscriptions: null

  # Config
  config:
    wipOnSave:
      type: 'boolean'
      default: true
      title: 'WIP on each file save'
      description: 'Creates a WIP checkpoint whenever you save a file.'

  activate: (state) ->

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    @packageName = require('../package.json').name


    # Register event listener for file saves
    shouldWipOnSave = atom.config.get "#{@packageName}.wipOnSave"
    if shouldWipOnSave
      @subscriptions.add atom.workspace.observeTextEditors (editor) =>
        editor.onDidSave (event) =>
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


  doGitWip: (path) ->
    return @errorNoGitRepo() unless atom.project.getRepositories().length > 0

    command = "git wip save"


    @getWorkingDirectories (directories) =>
      # TODO loop if multiple projects
      cdPath = directory = directories[0]
      if path? and @isFilePath(path)
        re = new RegExp directory
        unless re.test path
          messageFileNotInRepo = "The file that was saved is not part of this
            project's git repository. Therefore no WIP checkpoint was saved.
            If you're sure this file is part of the current project's repo,
            make sure you don't have multiple top-level folders open."
          @notifyUser messageFileNotInRepo, "error"
          return
        command += " \"Atom autosave: #{path}\" --editor -- #{path}"
      else
        command+= " \"Atom autosave\" --editor --untracked "
      shell.cd(cdPath)
      pwd = shell.pwd()
      if pwd is directory
        child = shell.exec command, {async: true}, (code, output) ->
          if code is 0
            @notifyUser "git WIP checkpoint created!", "success"
          if /error/.test output
            throw new Error "#{output}"
        # child.stdout.on 'data', (data) ->
        #   console.log data
      else
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

    exit = (code) -> console.log "which exite with #{code}"

    process = new BufferedProcess {command: command, args: ["git-wip"], stdout: stdout, exit: exit}






# random commentasdadzxczc cool making changessdkjk
