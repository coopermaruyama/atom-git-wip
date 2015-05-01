GitWipView = require './git-wip-view'
{CompositeDisposable, BufferedProcess, NotificationManger} = require 'atom'

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
      description: 'Creates a WIP checkpoint whenever you save a file. This is the recommended way to use this tool.'
    wipOnSchedule:
      type: 'boolean'
      default: false
      title: 'Enable WIP on specified time interval'
    wipOnScheduleInterval:
      type: 'integer'
      default: 60
      title: 'Scheduled WIP interval'
      description: 'Amount of time in minutes between each scheduled WIP'

  activate: (state) ->
    @gitWipView = new GitWipView(state.gitWipViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @gitWipView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable
    
    # Register event listener for file saves
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editor.onDidSave =>
        @doGitWip(editor.getPath())

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'git-wip:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'git-wip:add checkpoint': => @doGitWip()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @gitWipView.destroy()

  serialize: ->
    gitWipViewState: @gitWipView.serialize()

  toggle: ->
    console.log 'GitWip was toggled!'
    
    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  doGitWip: (filePath) ->
    return unless @checkGitWipBinExists()
    
    pathString = (new String(filePath))
    fileName = pathString.match(/\/([^\/]+\.\w+)$/)[0]
    filePath = pathString.replace fileName, ""
    # usage: git wip [ info | save <message> [ --editor | --untracked ] | log [ --pretty ] | delete ] [ [--] <file>... ]
    command = "./git-wip"
    args = ['save', '"atom checkpoint"', '--editor', '--', "#{filePath}"]
    options = {}
      # cwd: filePath
    
    stdout = (output) ->
      if /fatal: Not a git repository/.test output
        NotificationManger::addError "Not a git repo: please init!"
      console.log 'stdout', output
      dataStdout += output
      
    stderr = (output) ->
      console.warn 'stderr', output
      dataStderr += output
      
    exit = (code) =>
      exited = true
      console.debug "childprocess exited with code: #{code}"
    
    process = new BufferedProcess {command, args, options, stdout, stderr, exit}
    
    process.onWillThrowError (err) =>
      return unless err?
      throw new Erro("child process threw error: #{err.error} with code: #{err.error?.code}")
      
  
  checkGitWipBinExists: ->
    command: "which git-wip"
    process = new BufferedProcess {command: command}
    
    process.stdout.on 'data', (data) ->
      unless data and /git-wip/.test(data)
        throw new Error('bin git-wip not found: please install from https://github.com/bartman/git-wip and ensure it is in your bin path')
        false
      else
        true
        

      
  

    
  
