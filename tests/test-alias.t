  $ HGFOO=BAR; export HGFOO
  $ cat >> $HGRCPATH <<EOF
  > [alias]
  > # should clobber ci but not commit (issue2993)
  > ci = version
  > myinit = init
  > mycommit = commit
  > optionalrepo = showconfig alias.myinit
  > cleanstatus = status -c
  > unknown = bargle
  > ambiguous = s
  > recursive = recursive
  > disabled = email
  > nodefinition =
  > noclosingquotation = '
  > no--cwd = status --cwd elsewhere
  > no-R = status -R elsewhere
  > no--repo = status --repo elsewhere
  > no--repository = status --repository elsewhere
  > no--config = status --config a.config=1
  > mylog = log
  > lognull = log -r null
  > shortlog = log --template '{rev} {node|short} | {date|isodate}\n'
  > positional = log --template '{\$2} {\$1} | {date|isodate}\n'
  > dln = lognull --debug
  > nousage = rollback
  > put = export -r 0 -o "\$FOO/%R.diff"
  > blank = !printf '\n'
  > self = !printf '\$0\n'
  > echoall = !printf '\$@\n'
  > echo1 = !printf '\$1\n'
  > echo2 = !printf '\$2\n'
  > echo13 = !printf '\$1 \$3\n'
  > echotokens = !printf "%s\n" "\$@"
  > count = !hg log -r "\$@" --template=. | wc -c | sed -e 's/ //g'
  > mcount = !hg log \$@ --template=. | wc -c | sed -e 's/ //g'
  > rt = root
  > idalias = id
  > idaliaslong = id
  > idaliasshell = !echo test
  > parentsshell1 = !echo one
  > parentsshell2 = !echo two
  > escaped1 = !printf 'test\$\$test\n'
  > escaped2 = !sh -c 'echo "HGFOO is \$\$HGFOO"'
  > escaped3 = !sh -c 'echo "\$1 is \$\$\$1"'
  > escaped4 = !printf '\$\$0 \$\$@\n'
  > exit1 = !sh -c 'exit 1'
  > documented = id
  > documented:doc = an alias for the id command
  > 
  > [defaults]
  > mylog = -q
  > lognull = -q
  > log = -v
  > EOF


basic

  $ hg myinit alias


unknown

  $ hg unknown
  abort: alias 'unknown' resolves to unknown command 'bargle'
  [255]
  $ hg help unknown
  alias 'unknown' resolves to unknown command 'bargle'


ambiguous

  $ hg ambiguous
  abort: alias 'ambiguous' resolves to ambiguous command 's'
  [255]
  $ hg help ambiguous
  alias 'ambiguous' resolves to ambiguous command 's'


recursive

  $ hg recursive
  abort: alias 'recursive' resolves to unknown command 'recursive'
  [255]
  $ hg help recursive
  alias 'recursive' resolves to unknown command 'recursive'


disabled

  $ hg disabled
  abort: alias 'disabled' resolves to unknown command 'email'
  ('email' is provided by 'patchbomb' extension)
  [255]
  $ hg help disabled
  alias 'disabled' resolves to unknown command 'email'
  
  'email' is provided by the following extension:
  
      patchbomb     command to send changesets as (a series of) patch emails
  
  (use 'hg help extensions' for information on enabling extensions)


no definition

  $ hg nodef
  abort: no definition for alias 'nodefinition'
  [255]
  $ hg help nodef
  no definition for alias 'nodefinition'


no closing quotation

  $ hg noclosing
  abort: error in definition for alias 'noclosingquotation': No closing quotation
  [255]
  $ hg help noclosing
  error in definition for alias 'noclosingquotation': No closing quotation

"--" in alias definition should be preserved

  $ hg --config alias.dash='cat --' -R alias dash -r0
  abort: -r0 not under root '$TESTTMP/alias'
  (consider using '--cwd alias')
  [255]

invalid options

  $ hg no--cwd
  abort: error in definition for alias 'no--cwd': --cwd may only be given on the command line
  [255]
  $ hg help no--cwd
  error in definition for alias 'no--cwd': --cwd may only be given on the
  command line
  $ hg no-R
  abort: error in definition for alias 'no-R': -R may only be given on the command line
  [255]
  $ hg help no-R
  error in definition for alias 'no-R': -R may only be given on the command line
  $ hg no--repo
  abort: error in definition for alias 'no--repo': --repo may only be given on the command line
  [255]
  $ hg help no--repo
  error in definition for alias 'no--repo': --repo may only be given on the
  command line
  $ hg no--repository
  abort: error in definition for alias 'no--repository': --repository may only be given on the command line
  [255]
  $ hg help no--repository
  error in definition for alias 'no--repository': --repository may only be given
  on the command line
  $ hg no--config
  abort: error in definition for alias 'no--config': --config may only be given on the command line
  [255]
  $ hg no --config alias.no='--repo elsewhere --cwd elsewhere status'
  abort: error in definition for alias 'no': --repo/--cwd may only be given on the command line
  [255]
  $ hg no --config alias.no='--repo elsewhere'
  abort: error in definition for alias 'no': --repo may only be given on the command line
  [255]

optional repository

#if no-outer-repo
  $ hg optionalrepo
  init
#endif
  $ cd alias
  $ cat > .hg/hgrc <<EOF
  > [alias]
  > myinit = init -q
  > EOF
  $ hg optionalrepo
  init -q

no usage

  $ hg nousage
  no rollback information available
  [1]

  $ echo foo > foo
  $ hg commit -Amfoo
  adding foo

infer repository

  $ cd ..

#if no-outer-repo
  $ hg shortlog alias/foo
  0 e63c23eaa88a | 1970-01-01 00:00 +0000
#endif

  $ cd alias

with opts

  $ hg cleanst
  C foo


with opts and whitespace

  $ hg shortlog
  0 e63c23eaa88a | 1970-01-01 00:00 +0000

positional arguments

  $ hg positional
  abort: too few arguments for command alias
  [255]
  $ hg positional a
  abort: too few arguments for command alias
  [255]
  $ hg positional 'node|short' rev
  0 e63c23eaa88a | 1970-01-01 00:00 +0000

interaction with defaults

  $ hg mylog
  0:e63c23eaa88a
  $ hg lognull
  -1:000000000000


properly recursive

  $ hg dln
  changeset:   -1:0000000000000000000000000000000000000000
  phase:       public
  parent:      -1:0000000000000000000000000000000000000000
  parent:      -1:0000000000000000000000000000000000000000
  manifest:    -1:0000000000000000000000000000000000000000
  user:        
  date:        Thu Jan 01 00:00:00 1970 +0000
  extra:       branch=default
  


path expanding

  $ FOO=`pwd` hg put
  $ cat 0.diff
  # HG changeset patch
  # User test
  # Date 0 0
  #      Thu Jan 01 00:00:00 1970 +0000
  # Node ID e63c23eaa88ae77967edcf4ea194d31167c478b0
  # Parent  0000000000000000000000000000000000000000
  foo
  
  diff -r 000000000000 -r e63c23eaa88a foo
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/foo	Thu Jan 01 00:00:00 1970 +0000
  @@ -0,0 +1,1 @@
  +foo


simple shell aliases

  $ hg blank
  
  $ hg blank foo
  
  $ hg self
  self
  $ hg echoall
  
  $ hg echoall foo
  foo
  $ hg echoall 'test $2' foo
  test $2 foo
  $ hg echoall 'test $@' foo '$@'
  test $@ foo $@
  $ hg echoall 'test "$@"' foo '"$@"'
  test "$@" foo "$@"
  $ hg echo1 foo bar baz
  foo
  $ hg echo2 foo bar baz
  bar
  $ hg echo13 foo bar baz test
  foo baz
  $ hg echo2 foo
  
  $ hg echotokens
  
  $ hg echotokens foo 'bar $1 baz'
  foo
  bar $1 baz
  $ hg echotokens 'test $2' foo
  test $2
  foo
  $ hg echotokens 'test $@' foo '$@'
  test $@
  foo
  $@
  $ hg echotokens 'test "$@"' foo '"$@"'
  test "$@"
  foo
  "$@"
  $ echo bar > bar
  $ hg commit -qA -m bar
  $ hg count .
  1
  $ hg count 'branch(default)'
  2
  $ hg mcount -r '"branch(default)"'
  2

  $ tglog
  @  1: 042423737847 'bar'
  |
  o  0: e63c23eaa88a 'foo'
  


shadowing

  $ hg i
  hg: command 'i' is ambiguous:
      idalias idaliaslong idaliasshell identify import incoming init
  [255]
  $ hg id
  042423737847 tip
  $ hg ida
  hg: command 'ida' is ambiguous:
      idalias idaliaslong idaliasshell
  [255]
  $ hg idalias
  042423737847 tip
  $ hg idaliasl
  042423737847 tip
  $ hg idaliass
  test
  $ hg parentsshell
  hg: command 'parentsshell' is ambiguous:
      parentsshell1 parentsshell2
  [255]
  $ hg parentsshell1
  one
  $ hg parentsshell2
  two


shell aliases with global options

  $ hg init sub
  $ cd sub
  $ hg count 'branch(default)'
  abort: unknown revision 'default'!
  0
  $ hg -v count 'branch(default)'
  abort: unknown revision 'default'!
  0
  $ hg -R .. count 'branch(default)'
  abort: unknown revision 'default'!
  0
  $ hg --cwd .. count 'branch(default)'
  2
  $ hg echoall --cwd ..
  

"--" passed to shell alias should be preserved

  $ hg --config alias.printf='!printf "$@"' printf '%s %s %s\n' -- --cwd ..
  -- --cwd ..

repo specific shell aliases

  $ cat >> .hg/hgrc <<EOF
  > [alias]
  > subalias = !echo sub
  > EOF
  $ cat >> ../.hg/hgrc <<EOF
  > [alias]
  > mainalias = !echo main
  > EOF


shell alias defined in current repo

  $ hg subalias
  sub
  $ hg --cwd .. subalias > /dev/null
  hg: unknown command 'subalias'
  (did you mean idalias?)
  [255]
  $ hg -R .. subalias > /dev/null
  hg: unknown command 'subalias'
  (did you mean idalias?)
  [255]


shell alias defined in other repo

  $ hg mainalias > /dev/null
  hg: unknown command 'mainalias'
  (did you mean idalias?)
  [255]
  $ hg -R .. mainalias
  main
  $ hg --cwd .. mainalias
  main

typos get useful suggestions
  $ hg --cwd .. manalias
  hg: unknown command 'manalias'
  (did you mean one of idalias, mainalias, manifest?)
  [255]

shell aliases with escaped $ chars

  $ hg escaped1
  test$test
  $ hg escaped2
  HGFOO is BAR
  $ hg escaped3 HGFOO
  HGFOO is BAR
  $ hg escaped4 test
  $0 $@

abbreviated name, which matches against both shell alias and the
command provided extension, should be aborted.

  $ cat >> .hg/hgrc <<EOF
  > [extensions]
  > hgext.rebase =
  > EOF
#if windows
  $ cat >> .hg/hgrc <<EOF
  > [alias]
  > rebate = !echo this is %HG_ARGS%
  > EOF
#else
  $ cat >> .hg/hgrc <<EOF
  > [alias]
  > rebate = !echo this is \$HG_ARGS
  > EOF
#endif
  $ hg reba
  hg: command 'reba' is ambiguous:
      rebase rebate
  [255]
  $ hg rebat
  this is rebate
  $ hg rebat --foo-bar
  this is rebate --foo-bar

invalid arguments

  $ hg rt foo
  hg rt: invalid arguments
  hg rt
  
  alias for: hg root
  
  (use 'hg rt -h' to show more help)
  [255]

invalid global arguments for normal commands, aliases, and shell aliases

  $ hg --invalid root
  hg: option --invalid not recognized
  Mercurial Distributed SCM
  
  hg COMMAND [OPTIONS]
  
  These are some common Mercurial commands.  Use 'hg help commands' to list all
  commands, and 'hg help COMMAND' to get help on a specific command.
  
  Get the latest commits from the server:
  
   pull          pull changes from the specified source
  
  View commits:
  
   show          show commit in detail
   diff          show differences between commits
  
  Check out a commit:
  
   checkout      checkout a specific commit
  
  Work with your checkout:
  
   status        show changed files in the working directory
   add           add the specified files on the next commit
   remove        remove the specified files on the next commit
   revert        restore files to their checkout state
   forget        forget the specified files on the next commit
  
  Commit changes and modify commits:
  
   commit        commit the specified files or all outstanding changes
  
  Rearrange commits:
  
   rebase        move commits from one location to another
   graft         copy commits from a different location
  
  Other commands:
  
   config        show combined config settings from all hgrc files
   grep          search revision history for a pattern in specified files
  
  Additional help topics:
  
   filesets      specifying file sets
   glossary      glossary
   patterns      file name patterns
   revisions     specifying revisions
   templating    template usage
  [255]
  $ hg --invalid mylog
  hg: option --invalid not recognized
  Mercurial Distributed SCM
  
  hg COMMAND [OPTIONS]
  
  These are some common Mercurial commands.  Use 'hg help commands' to list all
  commands, and 'hg help COMMAND' to get help on a specific command.
  
  Get the latest commits from the server:
  
   pull          pull changes from the specified source
  
  View commits:
  
   show          show commit in detail
   diff          show differences between commits
  
  Check out a commit:
  
   checkout      checkout a specific commit
  
  Work with your checkout:
  
   status        show changed files in the working directory
   add           add the specified files on the next commit
   remove        remove the specified files on the next commit
   revert        restore files to their checkout state
   forget        forget the specified files on the next commit
  
  Commit changes and modify commits:
  
   commit        commit the specified files or all outstanding changes
  
  Rearrange commits:
  
   rebase        move commits from one location to another
   graft         copy commits from a different location
  
  Other commands:
  
   config        show combined config settings from all hgrc files
   grep          search revision history for a pattern in specified files
  
  Additional help topics:
  
   filesets      specifying file sets
   glossary      glossary
   patterns      file name patterns
   revisions     specifying revisions
   templating    template usage
  [255]
  $ hg --invalid blank
  hg: option --invalid not recognized
  Mercurial Distributed SCM
  
  hg COMMAND [OPTIONS]
  
  These are some common Mercurial commands.  Use 'hg help commands' to list all
  commands, and 'hg help COMMAND' to get help on a specific command.
  
  Get the latest commits from the server:
  
   pull          pull changes from the specified source
  
  View commits:
  
   show          show commit in detail
   diff          show differences between commits
  
  Check out a commit:
  
   checkout      checkout a specific commit
  
  Work with your checkout:
  
   status        show changed files in the working directory
   add           add the specified files on the next commit
   remove        remove the specified files on the next commit
   revert        restore files to their checkout state
   forget        forget the specified files on the next commit
  
  Commit changes and modify commits:
  
   commit        commit the specified files or all outstanding changes
  
  Rearrange commits:
  
   rebase        move commits from one location to another
   graft         copy commits from a different location
  
  Other commands:
  
   config        show combined config settings from all hgrc files
   grep          search revision history for a pattern in specified files
  
  Additional help topics:
  
   filesets      specifying file sets
   glossary      glossary
   patterns      file name patterns
   revisions     specifying revisions
   templating    template usage
  [255]

environment variable changes in alias commands

  $ cat > $TESTTMP/expandalias.py <<EOF
  > import os
  > from mercurial import cmdutil, commands, registrar
  > cmdtable = {}
  > command = registrar.command(cmdtable)
  > @command('expandalias')
  > def expandalias(ui, repo, name):
  >     alias = cmdutil.findcmd(name, commands.table)[1][0]
  >     ui.write('%s args: %s\n' % (name, ' '.join(alias.args)))
  >     os.environ['COUNT'] = '2'
  >     ui.write('%s args: %s (with COUNT=2)\n' % (name, ' '.join(alias.args)))
  > EOF

  $ cat >> $HGRCPATH <<'EOF'
  > [extensions]
  > expandalias = $TESTTMP/expandalias.py
  > [alias]
  > showcount = log -T "$COUNT" -r .
  > EOF

  $ COUNT=1 hg expandalias showcount
  showcount args: -T 1 -r .
  showcount args: -T 2 -r . (with COUNT=2)

This should show id:

  $ hg --config alias.log='id' log
  000000000000 tip

This shouldn't:

  $ hg --config alias.log='id' history

  $ cd ../..

return code of command and shell aliases:

  $ hg mycommit -R alias
  nothing changed
  [1]
  $ hg exit1
  [1]

#if no-outer-repo
  $ hg root
  abort: no repository found in '$TESTTMP' (.hg not found)!
  [255]
  $ hg --config alias.hgroot='!hg root' hgroot
  abort: no repository found in '$TESTTMP' (.hg not found)!
  [255]
#endif

documented aliases

  $ hg help documented
  hg documented [-nibtB] [-r REV] [SOURCE]
  
  an alias for the id command
  
  alias for: hg id
  
  identify the working directory or specified revision
  
      Print a summary identifying the repository state at REV using one or two
      parent hash identifiers, followed by a "+" if the working directory has
      uncommitted changes, the branch name (if not default), a list of tags, and
      a list of bookmarks.
  
      When REV is not given, print a summary of the current state of the
      repository.
  
      Specifying a path to a repository root or Mercurial bundle will cause
      lookup to operate on that repository/bundle.
  
      See 'hg log' for generating more information about specific revisions,
      including full hash identifiers.
  
      Returns 0 if successful.
  
  defined by: * (glob)
  [^ ].* (re) (?)
  
  Options:
  
   -r --rev REV       identify the specified revision
   -n --num           show local revision number
   -i --id            show global revision id
   -b --branch        show branch
   -t --tags          show tags
   -B --bookmarks     show bookmarks
   -e --ssh CMD       specify ssh command to use
      --remotecmd CMD specify hg command to run on the remote side
      --insecure      do not verify server certificate (ignoring web.cacerts
                      config)
  
  (some details hidden, use --verbose to show complete help)
  $ hg help commands | grep documented
   documented    an alias for the id command
