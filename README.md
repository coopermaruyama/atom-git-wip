# Git WIP: Automatic WIP checkpoints

Git WIP automatically creates Work-in-Progress checkpoints upon saving, or when manually activated. WIP checkpoints are stored in separate branches, so they don't affect the state of your current working tree.

Git WIP relies on a shell script which must be installed before you can use this package, and can be found here: https://github.com/bartman/git-wip (Big thanks to bartman for creating this very useful script!)

# Installation
  1. `cd ~/your-projects`
  2. `git clone https://github.com/bartman/git-wip`
  3. `ln -s ~/your-projects/git-wip/git-wip /usr/local/bin/git-wip` (you can copy it too but this way it's easier to update)
  4. \*Install via settings > packages, or: `apm install git-wip`


As of right now this package can do 3 things:
 1. Automatically create WIPs upon saving a file for that file.
 2. Create WIPs for the current file using the command palette.
 3. Create WIPs for the current project using the command palette.

Eventually if more people start using this package I will add functionality for things such as reviewing WIPs, recovery, using them squashing them into actual commits, etc.

---

---

**Below is the README from the original git-wip repo which contains a lot of useful info:**


### About

git-wip is a script that will manage Work In Progress (or WIP) branches.
WIP branches are mostly throw away but identify points of development
between commits.  The intent is to tie this script into your editor so
that each time you save your file, the git-wip script captures that
state in git.  git-wip also helps you return back to a previous state of
development.

Latest git-wip can be obtained from [github.com](http://github.com/bartman/git-wip)
git-wip was written by [Bart Trojanowski](mailto:bart@jukie.net)

### WIP branches

Wip branches are named after the branch that is being worked on, but are
prefixed with 'wip/'.  For example if you are working on a branch named
'feature' then the git-wip script will only manipulate the 'wip/feature'
branch.

When you run git-wip for the first time, it will capture all changes to
tracked files and all untracked (but not ignored) files, create a
commit, and make a new wip/*topic* branch point to it.

    --- * --- * --- *          <-- topic
                     \
                      *        <-- wip/topic

The next invocation of git-wip after a commit is made will continue to
evolve the work from the last wip/*topic* point.

    --- * --- * --- *          <-- topic
                     \
                      *
                       \
                        *      <-- wip/topic

When git-wip is invoked after a commit is made, the state of the
wip/*topic* branch will be reset back to your *topic* branch and the new
changes to the working tree will be caputred on a new commit.

    --- * --- * --- * --- *    <-- topic
                     \     \
                      *     *  <-- wip/topic
                       \
                        *

While the old wip/*topic* work is no longer accessible directly, it can
always be recovered from git-reflog.  In the above example you could use
`wip/topic@{1}` to access the dangling references.

### git-wip command

The git-wip command can be invoked in several differnet ways.

* `git wip`
  
  In this mode, git-wip will create a new commit on the wip/*topic*
  branch (creating it if needed) as described above.

* `git wip save "description"`
  
  Similar to `git wip`, but allows for a custom commit message.

* `git wip log`
  
  Show the list of the work that leads upto the last WIP commit.  This
  is similar to invoking:
  
  `git log --stat wip/$branch...$(git merge-base wip/$branch $branch)`

# recovery

Should you discover that you made some really bad changes in your code,
from which you want to recover, here is what to do.

First we need to find the commit we are interested in.  If it's the most recent
then it can be referenced with `wip/master` (assuming your branch is `master`),
otherwise you may need to find the one you want using:

    git reflog show wip/master

I personally prefer to inspect the reflog with `git log -g`, and sometimes
with `-p` also:

    git log -g -p wip/master

Once you've picked a commit, you need to checkout the files, note that we are not
switching the commit that your branch points to (HEAD will continue to reference
the last real commit on the branch).  We are just checking out the files:

    git checkout ref -- .

Here `ref` could be a SHA1 or `wip/master`.  If you only want to recover one file,
then use it's path instead of the *dot*.

The changes will be staged in the index and checked out into the working tree, to
review what the differences are between the last commit, use:

    git diff --cached

If you want, you can unstage all or some with `git reset`, optionally specifying a
filename to unstage.  You can then stage them again using `git add` or `git add -p`.
Finally, when you're happy with the changes, commit them.


<!-- vim: set ft=markdown -->
