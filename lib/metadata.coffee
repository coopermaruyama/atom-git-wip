Metadata =
messages:
  fileNotFoundInRepo: "The file that was saved is not part of this
    project's git repository. Therefore no WIP checkpoint was saved.
    If you're sure this file is part of the current project's repo,
    make sure you don't have multiple top-level folders open."
  binaryNotFound: "bin git-wip not found: please install from https://github.com/bartman/git-wip and ensure it is in your bin path"
  # debug messages
  pathFoundInRepo: "was found in repo - continuing.."
  pathInvalidForRepo: "does not belong to repo - aborting..."
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


# Export
module.exports = Metadata
