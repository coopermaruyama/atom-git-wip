GitWip = require '../lib/git-wip'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "GitWip", ->
  [workspaceElement, activationPromise] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('git-wip')

  describe "when the git-wip:toggle event is triggered", ->
    it "hides and shows the modal panel", ->
      # Before the activation event the view is not on the DOM, and no panel
      # has been created
      expect(workspaceElement.querySelector('.git-wip')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'git-wip:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.querySelector('.git-wip')).toExist()

        atomGitWipElement = workspaceElement.querySelector('.git-wip')
        expect(atomGitWipElement).toExist()

        atomGitWipPanel = atom.workspace.panelForItem(atomGitWipElement)
        expect(atomGitWipPanel.isVisible()).toBe true
        atom.commands.dispatch workspaceElement, 'git-wip:toggle'
        expect(atomGitWipPanel.isVisible()).toBe false

    it "hides and shows the view", ->
      # This test shows you an integration test testing at the view level.

      # Attaching the workspaceElement to the DOM is required to allow the
      # `toBeVisible()` matchers to work. Anything testing visibility or focus
      # requires that the workspaceElement is on the DOM. Tests that attach the
      # workspaceElement to the DOM are generally slower than those off DOM.
      jasmine.attachToDOM(workspaceElement)

      expect(workspaceElement.querySelector('.git-wip')).not.toExist()

      # This is an activation event, triggering it causes the package to be
      # activated.
      atom.commands.dispatch workspaceElement, 'git-wip:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        # Now we can test for view visibility
        atomGitWipElement = workspaceElement.querySelector('.git-wip')
        expect(atomGitWipElement).toBeVisible()
        atom.commands.dispatch workspaceElement, 'git-wip:toggle'
        expect(atomGitWipElement).not.toBeVisible()
        
  describe "node environment", ->
    
    it "doesnt have an empty PATH variable", ->
      expect process.env.PATH
        .to.not.be.empty()
    it "should contain forward slashes and colons", ->
      expect /.*:.*\/.*/.test(process.env.PATH)
        .to.be true
  describe "shell environment", ->
    [process, stdout, stderr, exit, args, command] = []
    
    BeforeEach ->
      stdout = (data) ->
        console.log "stdout: #{data}"
        return data
      stderr = (output) ->
        console.warn "stderr: #{output}"
        return output
      exit = (code) ->
        console.log "exit code: #{exit}"
        return code
    it "fails because pending", ->
      expect(1).to.equal 2
  describe "git-wip:add checkpoint", ->
    it "creates a git wip checkpoint when triggered", ->
        expect(1).to.equal 2
