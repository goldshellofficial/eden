#chg-compatible

  $ hg init repo
  $ cd repo

  $ cat > $TESTTMP/hook.sh <<'EOF'
  > echo "test-hook-bookmark: $HG_BOOKMARK:  $HG_OLDNODE -> $HG_NODE"
  > EOF
  $ TESTHOOK="hooks.txnclose-bookmark.test=sh $TESTTMP/hook.sh"

no bookmarks

  $ hg bookmarks
  no bookmarks set

  $ hg bookmarks -Tjson
  [
  ]

bookmark rev -1

  $ hg bookmark X --config "$TESTHOOK"
  test-hook-bookmark: X:   -> 0000000000000000000000000000000000000000

list bookmarks

  $ hg bookmarks
   * X                         000000000000

list bookmarks with color

  $ hg --config extensions.color= --config color.mode=ansi \
  >    bookmarks --color=always
  \x1b[0;32m * \x1b[0m\x1b[0;32mX\x1b[0m\x1b[0;32m                         000000000000\x1b[0m (esc)

  $ echo a > a
  $ hg add a
  $ hg commit -m 0 --config "$TESTHOOK"
  test-hook-bookmark: X:  0000000000000000000000000000000000000000 -> f7b1eb17ad24730a1651fccd46c43826d1bbc2ac

bookmark X moved to rev 0

  $ hg bookmarks
   * X                         f7b1eb17ad24

look up bookmark

  $ hg log -r X
  commit:      f7b1eb17ad24
  bookmark:    X
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     0
  

second bookmark for rev 0, command should work even with ui.strict on

  $ hg --config ui.strict=1 bookmark X2 --config "$TESTHOOK"
  test-hook-bookmark: X2:   -> f7b1eb17ad24730a1651fccd46c43826d1bbc2ac

bookmark rev -1 again

  $ hg bookmark -r null Y

list bookmarks

  $ hg bookmarks
     X                         f7b1eb17ad24
   * X2                        f7b1eb17ad24
     Y                         000000000000

  $ echo b > b
  $ hg add b
  $ hg commit -m 1 --config "$TESTHOOK"
  test-hook-bookmark: X2:  f7b1eb17ad24730a1651fccd46c43826d1bbc2ac -> 925d80f479bb026b0fb3deb27503780b13f74123

  $ hg bookmarks -Tjson
  [
   {
    "active": false,
    "bookmark": "X",
    "node": "f7b1eb17ad24730a1651fccd46c43826d1bbc2ac"
   },
   {
    "active": true,
    "bookmark": "X2",
    "node": "925d80f479bb026b0fb3deb27503780b13f74123"
   },
   {
    "active": false,
    "bookmark": "Y",
    "node": "0000000000000000000000000000000000000000"
   }
  ]

bookmarks revset

  $ hg log -r 'bookmark()'
  commit:      f7b1eb17ad24
  bookmark:    X
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     0
  
  commit:      925d80f479bb
  bookmark:    X2
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     1
  
  $ hg log -r 'bookmark(Y)'
  $ hg log -r 'bookmark(X2)'
  commit:      925d80f479bb
  bookmark:    X2
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     1
  
  $ hg log -r 'bookmark("re:X")'
  commit:      f7b1eb17ad24
  bookmark:    X
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     0
  
  commit:      925d80f479bb
  bookmark:    X2
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     1
  
  $ hg log -r 'bookmark("literal:X")'
  commit:      f7b1eb17ad24
  bookmark:    X
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     0
  

  $ hg log -r 'bookmark(unknown)'
  abort: bookmark 'unknown' does not exist!
  [255]
  $ hg log -r 'bookmark("literal:unknown")'
  abort: bookmark 'unknown' does not exist!
  [255]
  $ hg log -r 'bookmark("re:unknown")'
  abort: no bookmarks exist that match 'unknown'!
  [255]
  $ hg log -r 'present(bookmark("literal:unknown"))'
  $ hg log -r 'present(bookmark("re:unknown"))'

  $ hg help revsets | grep 'bookmark('
      "bookmark([name])"
      "remotebookmark([name])"

bookmarks X and X2 moved to rev 1, Y at rev -1

  $ hg bookmarks
     X                         f7b1eb17ad24
   * X2                        925d80f479bb
     Y                         000000000000

bookmark rev 0 again

  $ hg bookmark -r 'desc(0)' Z

  $ hg update X
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  (activating bookmark X)
  $ echo c > c
  $ hg add c
  $ hg commit -m 2

bookmarks X moved to rev 2, Y at rev -1, Z at rev 0

  $ hg bookmarks
   * X                         db815d6d32e6
     X2                        925d80f479bb
     Y                         000000000000
     Z                         f7b1eb17ad24

rename nonexistent bookmark

  $ hg bookmark -m A B
  abort: bookmark 'A' does not exist
  [255]

rename to existent bookmark

  $ hg bookmark -m X Y
  abort: bookmark 'Y' already exists (use -f to force)
  [255]

force rename to existent bookmark

  $ hg bookmark -f -m X Y

rename bookmark using .

  $ hg book rename-me
  $ hg book -m . renamed --config "$TESTHOOK"
  test-hook-bookmark: rename-me:  db815d6d32e69058eadefc8cffbad37675707975 -> 
  test-hook-bookmark: renamed:   -> db815d6d32e69058eadefc8cffbad37675707975
  $ hg bookmark
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         f7b1eb17ad24
   * renamed                   db815d6d32e6
  $ hg up -q Y
  $ hg book -d renamed --config "$TESTHOOK"
  test-hook-bookmark: renamed:  db815d6d32e69058eadefc8cffbad37675707975 -> 

rename bookmark using . with no active bookmark

  $ hg book rename-me
  $ hg book -i rename-me
  $ hg book -m . renamed
  abort: no active bookmark
  [255]
  $ hg up -q Y
  $ hg book -d rename-me

delete bookmark using .

  $ hg book delete-me
  $ hg book -d .
  $ hg bookmark
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         f7b1eb17ad24
  $ hg up -q Y

delete bookmark using . with no active bookmark

  $ hg book delete-me
  $ hg book -i delete-me
  $ hg book -d .
  abort: no active bookmark
  [255]
  $ hg up -q Y
  $ hg book -d delete-me

list bookmarks

  $ hg bookmark
     X2                        925d80f479bb
   * Y                         db815d6d32e6
     Z                         f7b1eb17ad24

bookmarks from a revset
  $ hg bookmark -r '.^1' REVSET
  $ hg bookmark -r ':tip' TIP
  $ hg up -q TIP
  $ hg bookmarks
     REVSET                    f7b1eb17ad24
   * TIP                       db815d6d32e6
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         f7b1eb17ad24

  $ hg bookmark -d REVSET
  $ hg bookmark -d TIP

rename without new name or multiple names

  $ hg bookmark -m Y
  abort: new bookmark name required
  [255]
  $ hg bookmark -m Y Y2 Y3
  abort: only one new bookmark name allowed
  [255]

delete without name

  $ hg bookmark -d
  abort: bookmark name required
  [255]

delete nonexistent bookmark

  $ hg bookmark -d A
  abort: bookmark 'A' does not exist
  [255]

ensure bookmark names are deduplicated before deleting
  $ hg book delete-me
  $ hg book -d delete-me delete-me

bookmark name with spaces should be stripped

  $ hg bookmark ' x  y '

list bookmarks

  $ hg bookmarks
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         f7b1eb17ad24
   * x  y                      db815d6d32e6

look up stripped bookmark name

  $ hg log -r '"x  y"'
  commit:      db815d6d32e6
  bookmark:    Y
  bookmark:    x  y
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     2
  

reject bookmark name with newline

  $ hg bookmark '
  > '
  abort: bookmark names cannot consist entirely of whitespace
  [255]

  $ hg bookmark -m Z '
  > '
  abort: bookmark names cannot consist entirely of whitespace
  [255]

bookmark with reserved name

  $ hg bookmark tip
  abort: the name 'tip' is reserved
  [255]

  $ hg bookmark .
  abort: the name '.' is reserved
  [255]

  $ hg bookmark null
  abort: the name 'null' is reserved
  [255]


bookmark with existing name

  $ hg bookmark X2
  abort: bookmark 'X2' already exists (use -f to force)
  [255]

  $ hg bookmark -m Y Z
  abort: bookmark 'Z' already exists (use -f to force)
  [255]

bookmark with name of branch

  $ hg bookmark default
  bookmark default matches a changeset hash
  (did you leave a -r out of an 'hg bookmark' command?)
  $ hg bookmark -f default
  $ hg book -d default

  $ hg bookmark -f -m Y default
  $ hg book -m default Y

bookmark with integer name

  $ hg bookmark 10
  abort: cannot use an integer as a name
  [255]

bookmark with a name that matches a node id
  $ hg bookmark 925d80f479bb db815d6d32e6 --config "$TESTHOOK"
  bookmark 925d80f479bb matches a changeset hash
  (did you leave a -r out of an 'hg bookmark' command?)
  bookmark db815d6d32e6 matches a changeset hash
  (did you leave a -r out of an 'hg bookmark' command?)
  test-hook-bookmark: 925d80f479bb:   -> db815d6d32e69058eadefc8cffbad37675707975
  test-hook-bookmark: db815d6d32e6:   -> db815d6d32e69058eadefc8cffbad37675707975
  $ hg bookmark -d 925d80f479bb
  $ hg bookmark -d db815d6d32e6

  $ cd ..

bookmark with a name that matches an ambiguous node id

  $ hg init ambiguous
  $ cd ambiguous
  $ echo 0 > a
  $ hg ci -qAm 0
  $ for i in 1057 2857 4025; do
  >   hg up -q 0
  >   echo $i > a
  >   hg ci -qm $i
  > done
  $ hg up -q null
  $ hg log -rb4e73ffab476aa0ee32ed81ca51e07169844bc6a: -T '{node}\n'
  b4e73ffab476aa0ee32ed81ca51e07169844bc6a
  c56256a09cd28e5764f32e8e2810d0f01e2e357a
  c5623987d205cd6d9d8389bfc40fff9dbb670b48
  c562ddd9c94164376c20b86b0b4991636a3bf84f

  $ hg bookmark -rb4e73ffab476aa0ee32ed81ca51e07169844bc6a c562
  $ hg bookmarks
     c562                      b4e73ffab476

  $ cd ..

incompatible options

  $ cd repo

  $ hg bookmark -m Y -d Z
  abort: --delete and --rename are incompatible
  [255]

  $ hg bookmark -r 1 -d Z
  abort: --rev is incompatible with --delete
  [255]

  $ hg bookmark -r 1 -m Z Y
  abort: --rev is incompatible with --rename
  [255]

force bookmark with existing name

  $ hg bookmark -f X2 --config "$TESTHOOK"
  test-hook-bookmark: X2:  925d80f479bb026b0fb3deb27503780b13f74123 -> db815d6d32e69058eadefc8cffbad37675707975

force bookmark back to where it was, should deactivate it

  $ hg bookmark -fr'desc(1)' X2
  $ hg bookmarks
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         f7b1eb17ad24
     x  y                      db815d6d32e6

forward bookmark to descendant without --force

  $ hg bookmark Z
  moving bookmark 'Z' forward from f7b1eb17ad24

list bookmarks

  $ hg bookmark
     X2                        925d80f479bb
     Y                         db815d6d32e6
   * Z                         db815d6d32e6
     x  y                      db815d6d32e6

revision but no bookmark name

  $ hg bookmark -r .
  abort: bookmark name required
  [255]

bookmark name with whitespace only

  $ hg bookmark ' '
  abort: bookmark names cannot consist entirely of whitespace
  [255]

  $ hg bookmark -m Y ' '
  abort: bookmark names cannot consist entirely of whitespace
  [255]

invalid bookmark

  $ hg bookmark 'foo:bar'
  abort: ':' cannot be used in a name
  [255]

  $ hg bookmark 'foo
  > bar'
  abort: '\n' cannot be used in a name
  [255]

the bookmark extension should be ignored now that it is part of core

  $ echo "[extensions]" >> $HGRCPATH
  $ echo "bookmarks=" >> $HGRCPATH
  $ hg bookmarks
     X2                        925d80f479bb
     Y                         db815d6d32e6
   * Z                         db815d6d32e6
     x  y                      db815d6d32e6

test summary

  $ hg summary
  parent: db815d6d32e6 
   2
  bookmarks: *Z Y x  y
  commit: (clean)
  phases: 3 draft

test id

  $ hg id
  db815d6d32e6 Y/Z/x  y

  $ echo foo > f1

activate bookmark on working dir parent without --force

  $ hg bookmark --inactive Z
  $ hg bookmark Z

test clone

  $ hg bookmark -r 'desc(2)' -i @
  $ hg bookmark -r 'desc(2)' -i a@
  $ hg bookmarks
     @                         db815d6d32e6
     X2                        925d80f479bb
     Y                         db815d6d32e6
   * Z                         db815d6d32e6
     a@                        db815d6d32e6
     x  y                      db815d6d32e6
  $ hg clone . cloned-bookmarks
  updating to bookmark @
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R cloned-bookmarks bookmarks
   * @                         db815d6d32e6
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         db815d6d32e6
     a@                        db815d6d32e6
     x  y                      db815d6d32e6

test clone with pull protocol

  $ hg clone --pull . cloned-bookmarks-pull
  requesting all changes
  adding changesets
  adding manifests
  adding file changes
  added 3 changesets with 3 changes to 3 files
  updating to bookmark @
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R cloned-bookmarks-pull bookmarks
   * @                         db815d6d32e6
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         db815d6d32e6
     a@                        db815d6d32e6
     x  y                      db815d6d32e6

delete multiple bookmarks at once

  $ hg bookmark -d @ a@

test clone with a bookmark named "default" (issue3677)

  $ hg bookmark -r 'desc(1)' -f -i default
  $ hg clone . cloned-bookmark-default
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R cloned-bookmark-default bookmarks
     X2                        925d80f479bb
     Y                         db815d6d32e6
     Z                         db815d6d32e6
     default                   925d80f479bb
     x  y                      db815d6d32e6
  $ hg -R cloned-bookmark-default parents -q
  db815d6d32e6
  $ hg bookmark -d default

test clone with a specific revision

  $ hg clone -r 925d80 . cloned-bookmarks-rev
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R cloned-bookmarks-rev bookmarks
     X2                        925d80f479bb

test clone with update to a bookmark

  $ hg clone -u Z . ../cloned-bookmarks-update
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R ../cloned-bookmarks-update bookmarks
     X2                        925d80f479bb
     Y                         db815d6d32e6
   * Z                         db815d6d32e6
     x  y                      db815d6d32e6

create bundle with two heads

  $ hg clone . tobundle
  updating to branch default
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo x > tobundle/x
  $ hg -R tobundle add tobundle/x
  $ hg -R tobundle commit -m'x'
  $ hg -R tobundle update -r -2
  0 files updated, 0 files merged, 1 files removed, 0 files unresolved
  $ echo y > tobundle/y
  $ hg -R tobundle add tobundle/y
  $ hg -R tobundle commit -m'y'
  $ hg -R tobundle bundle tobundle.hg
  searching for changes
  2 changesets found
  $ hg unbundle tobundle.hg
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files

update to active bookmark if it's not the parent

(it is known issue that fsmonitor can't handle nested repositories. In
this test scenario, cloned-bookmark-default and tobundle exist in the
working directory of current repository)

  $ hg summary
  parent: db815d6d32e6 
   2
  bookmarks: *Z Y x  y
  commit: * unknown* (glob)
  phases: 5 draft
  $ hg update
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  updating bookmark Z
  $ hg bookmarks
     X2                        925d80f479bb
     Y                         db815d6d32e6
   * Z                         9c404beeabc2
     x  y                      db815d6d32e6

pull --update works the same as pull && update

  $ hg bookmark -r'desc(x)' Y
  moving bookmark 'Y' forward from db815d6d32e6
  $ cp -R ../cloned-bookmarks-update ../cloned-bookmarks-manual-update
  $ cp -R ../cloned-bookmarks-update ../cloned-bookmarks-manual-update-with-divergence

(manual version)

  $ hg -R ../cloned-bookmarks-manual-update update Y
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (activating bookmark Y)
  $ hg -R ../cloned-bookmarks-manual-update pull .
  pulling from .
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  updating bookmark Y
  updating bookmark Z

(# tests strange but with --date crashing when bookmark have to move)

  $ hg -R ../cloned-bookmarks-manual-update update -d 1986
  abort: revision matching date not found
  [255]
  $ hg -R ../cloned-bookmarks-manual-update update
  updating to active bookmark Y
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

(all in one version)

  $ hg -R ../cloned-bookmarks-update update Y
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (activating bookmark Y)
  $ hg -R ../cloned-bookmarks-update pull --update .
  pulling from .
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  updating bookmark Y
  updating bookmark Z
  updating to active bookmark Y
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

We warn about divergent during bare update to the active bookmark

  $ hg -R ../cloned-bookmarks-manual-update-with-divergence update Y
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (activating bookmark Y)
  $ hg -R ../cloned-bookmarks-manual-update-with-divergence bookmarks -r X2 Y@1
  $ hg -R ../cloned-bookmarks-manual-update-with-divergence bookmarks
     X2                        925d80f479bb
   * Y                         db815d6d32e6
     Y@1                       925d80f479bb
     Z                         db815d6d32e6
     x  y                      db815d6d32e6
  $ hg -R ../cloned-bookmarks-manual-update-with-divergence pull
  pulling from $TESTTMP/repo
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 2 changesets with 2 changes to 2 files
  updating bookmark Y
  updating bookmark Z
  $ hg -R ../cloned-bookmarks-manual-update-with-divergence update
  updating to active bookmark Y
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  1 other divergent bookmarks for "Y"

remove all bookmarks

  $ hg book -d X2 Y Z 'x  y'

test stripping a non-checked-out but bookmarked revision

  $ hg log --graph
  @  commit:      9c404beeabc2
  ???  user:        test
  ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ???  summary:     y
  ???
  ??? o  commit:      125c9a1d6df6
  ?????????  user:        test
  ???    date:        Thu Jan 01 00:00:00 1970 +0000
  ???    summary:     x
  ???
  o  commit:      db815d6d32e6
  ???  user:        test
  ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ???  summary:     2
  ???
  ??? o  commit:      925d80f479bb
  ?????????  user:        test
  ???    date:        Thu Jan 01 00:00:00 1970 +0000
  ???    summary:     1
  ???
  o  commit:      f7b1eb17ad24
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     0
  
  $ hg book should-end-on-two
  $ hg co --clean 'desc(y)'
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (leaving bookmark should-end-on-two)
  $ hg book four
  $ hg debugstrip 'desc(x)'
should-end-on-two should end up pointing to revision 2, as that's the
tipmost surviving ancestor of the stripped revision.
  $ hg log --graph
  @  commit:      9c404beeabc2
  ???  bookmark:    four
  ???  bookmark:    should-end-on-two
  ???  user:        test
  ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ???  summary:     y
  ???
  o  commit:      db815d6d32e6
  ???  user:        test
  ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ???  summary:     2
  ???
  ??? o  commit:      925d80f479bb
  ?????????  user:        test
  ???    date:        Thu Jan 01 00:00:00 1970 +0000
  ???    summary:     1
  ???
  o  commit:      f7b1eb17ad24
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     0
  

no-op update doesn't deactivate bookmarks

(it is known issue that fsmonitor can't handle nested repositories. In
this test scenario, cloned-bookmark-default and tobundle exist in the
working directory of current repository)

  $ hg bookmarks
   * four                      9c404beeabc2
     should-end-on-two         9c404beeabc2
  $ hg up four
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg up
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg sum
  parent: 9c404beeabc2 
   y
  bookmarks: *four should-end-on-two
  commit: 2 unknown (clean)
  phases: 4 draft

test clearing divergent bookmarks of linear ancestors

  $ hg bookmark Z -r 'desc(0)'
  $ hg bookmark Z@1 -r 'desc(1)'
  $ hg bookmark Z@2 -r 'desc(2)'
  $ hg bookmark Z@3 -r 'desc(y)'
  $ hg book
     Z                         f7b1eb17ad24
     Z@1                       925d80f479bb
     Z@2                       db815d6d32e6
     Z@3                       9c404beeabc2
   * four                      9c404beeabc2
     should-end-on-two         9c404beeabc2
  $ hg bookmark Z
  moving bookmark 'Z' forward from f7b1eb17ad24
  $ hg book
   * Z                         9c404beeabc2
     Z@1                       925d80f479bb
     four                      9c404beeabc2
     should-end-on-two         9c404beeabc2

test clearing only a single divergent bookmark across branches

  $ hg book foo -r 'desc(1)'
  $ hg book foo@1 -r 'desc(0)'
  $ hg book foo@2 -r 'desc(2)'
  $ hg book foo@3 -r 'desc(y)'
  $ hg book foo -r foo@3
  $ hg book
   * Z                         9c404beeabc2
     Z@1                       925d80f479bb
     foo                       9c404beeabc2
     foo@1                     f7b1eb17ad24
     foo@2                     db815d6d32e6
     four                      9c404beeabc2
     should-end-on-two         9c404beeabc2

pull --update works the same as pull && update (case #2)

It is assumed that "hg pull" itself doesn't update current active
bookmark ('Y' in tests below).

  $ hg pull -q ../cloned-bookmarks-update

(pulling revision on another named branch with --update updates
neither the working directory nor current active bookmark: "no-op"
case)

  $ echo yy >> y
  $ hg commit -m yy

  $ hg -R ../cloned-bookmarks-update bookmarks | grep ' Y '
   * Y                         125c9a1d6df6
  $ hg -R ../cloned-bookmarks-update pull . --update
  pulling from .
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  updating bookmark Z
  adding remote bookmark foo
  adding remote bookmark four
  adding remote bookmark should-end-on-two
  0 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg -R ../cloned-bookmarks-update parents -T "{node|short}\n"
  125c9a1d6df6
  $ hg -R ../cloned-bookmarks-update bookmarks | grep ' Y '
   * Y                         125c9a1d6df6

(pulling revision on current named/topological branch with --update
updates the working directory and current active bookmark)

  $ hg update -C -q 125c9a1d6df6
  $ echo xx >> x
  $ hg commit -m xx

  $ hg -R ../cloned-bookmarks-update bookmarks | grep ' Y '
   * Y                         125c9a1d6df6
  $ hg -R ../cloned-bookmarks-update pull . --update
  pulling from .
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 1 changes to 1 files
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  updating bookmark Y
  $ hg -R ../cloned-bookmarks-update parents -T "{node|short}\n"
  81dcce76aa0b
  $ hg -R ../cloned-bookmarks-update bookmarks | grep ' Y '
   * Y                         81dcce76aa0b

  $ cd ..

ensure changelog is written before bookmarks
  $ hg init orderrepo
  $ cd orderrepo
  $ touch a
  $ hg commit -Aqm one
  $ hg book mybook
  $ echo a > a

  $ cat > $TESTTMP/pausefinalize.py <<EOF
  > from __future__ import absolute_import
  > import os
  > import time
  > from edenscm.mercurial import extensions, localrepo
  > def transaction(orig, self, desc, report=None):
  >    tr = orig(self, desc, report)
  >    def sleep(*args, **kwargs):
  >        retry = 20
  >        while retry > 0 and not os.path.exists("$TESTTMP/unpause"):
  >            retry -= 1
  >            time.sleep(0.5)
  >        if os.path.exists("$TESTTMP/unpause"):
  >            os.remove("$TESTTMP/unpause")
  >    # It is important that this finalizer start with 'a', so it runs before
  >    # the changelog finalizer appends to the changelog.
  >    tr.addfinalize('a-sleep', sleep)
  >    return tr
  > 
  > def extsetup(ui):
  >    # This extension inserts an artifical pause during the transaction
  >    # finalizer, so we can run commands mid-transaction-close.
  >    extensions.wrapfunction(localrepo.localrepository, 'transaction',
  >                            transaction)
  > EOF
  $ hg commit -qm two --config extensions.pausefinalize=$TESTTMP/pausefinalize.py &
  $ sleep 2
  $ hg log -r .
  commit:      867bc5792c8c
  bookmark:    mybook
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     one
  
  $ hg bookmarks
   * mybook                    867bc5792c8c
  $ touch $TESTTMP/unpause

  $ cd ..

check whether HG_PENDING makes pending changes only in related
repositories visible to an external hook.

(emulate a transaction running concurrently by copied
.hg/bookmarks.pending in subsequent test)

  $ cat > $TESTTMP/savepending.sh <<EOF
  > cp .hg/store/bookmarks.pending .hg/store/bookmarks.pending.saved
  > exit 1 # to avoid adding new bookmark for subsequent tests
  > EOF

  $ hg init unrelated
  $ cd unrelated
  $ echo a > a
  $ hg add a
  $ hg commit -m '#0'
  $ hg --config hooks.pretxnclose="sh $TESTTMP/savepending.sh" bookmarks INVISIBLE
  transaction abort!
  rollback completed
  abort: pretxnclose hook exited with status 1
  [255]
  $ cp .hg/store/bookmarks.pending.saved .hg/store/bookmarks.pending

(check visible bookmarks while transaction running in repo)

  $ cat > $TESTTMP/checkpending.sh <<EOF
  > echo "@repo"
  > hg -R "$TESTTMP/repo" bookmarks
  > echo "@unrelated"
  > hg -R "$TESTTMP/unrelated" bookmarks
  > exit 1 # to avoid adding new bookmark for subsequent tests
  > EOF

  $ cd ../repo
  $ hg --config hooks.pretxnclose="sh $TESTTMP/checkpending.sh" bookmarks NEW
  @repo
   * NEW                       81dcce76aa0b
     X2                        925d80f479bb
     Y                         125c9a1d6df6
     Z                         f047c86095b7
     Z@1                       925d80f479bb
     foo                       9c404beeabc2
     foo@1                     f7b1eb17ad24
     foo@2                     db815d6d32e6
     four                      9c404beeabc2
     should-end-on-two         9c404beeabc2
     x  y                      db815d6d32e6
  @unrelated
  no bookmarks set
  transaction abort!
  rollback completed
  abort: pretxnclose hook exited with status 1
  [255]

Check pretxnclose-bookmark can abort a transaction
--------------------------------------------------

add hooks:

* to prevent NEW bookmark on a non-public changeset
* to prevent non-forward move of NEW bookmark

  $ cat << EOF >> .hg/hgrc
  > [hooks]
  > pretxnclose-bookmark.force-public  = sh -c "(echo \$HG_BOOKMARK| grep -v NEW > /dev/null) || [ -z \"\$HG_NODE\" ] || (hg log -r \"\$HG_NODE\" -T '{phase}' | grep public > /dev/null)"
  > pretxnclose-bookmark.force-forward = sh -c "(echo \$HG_BOOKMARK| grep -v NEW > /dev/null) || [ -z \"\$HG_NODE\" ] || (hg log -r \"max(\$HG_OLDNODE::\$HG_NODE)\" -T 'MATCH' | grep MATCH > /dev/null)"
  > EOF

  $ hg log -G -T phases
  @  commit:      81dcce76aa0b
  ???  phase:       draft
  ???  user:        test
  ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ???  summary:     xx
  ???
  ??? o  commit:      f047c86095b7
  ??? ???  bookmark:    Z
  ??? ???  phase:       draft
  ??? ???  user:        test
  ??? ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ??? ???  summary:     yy
  ??? ???
  o ???  commit:      125c9a1d6df6
  ??? ???  bookmark:    Y
  ??? ???  phase:       public
  ??? ???  user:        test
  ??? ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ??? ???  summary:     x
  ??? ???
  ??? o  commit:      9c404beeabc2
  ?????????  bookmark:    foo
  ???    bookmark:    four
  ???    bookmark:    should-end-on-two
  ???    phase:       public
  ???    user:        test
  ???    date:        Thu Jan 01 00:00:00 1970 +0000
  ???    summary:     y
  ???
  o  commit:      db815d6d32e6
  ???  bookmark:    foo@2
  ???  bookmark:    x  y
  ???  phase:       public
  ???  user:        test
  ???  date:        Thu Jan 01 00:00:00 1970 +0000
  ???  summary:     2
  ???
  ??? o  commit:      925d80f479bb
  ?????????  bookmark:    X2
  ???    bookmark:    Z@1
  ???    phase:       public
  ???    user:        test
  ???    date:        Thu Jan 01 00:00:00 1970 +0000
  ???    summary:     1
  ???
  o  commit:      f7b1eb17ad24
     bookmark:    foo@1
     phase:       public
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     0
  

attempt to create on a default changeset

  $ hg bookmark -r 81dcce76aa0b NEW
  transaction abort!
  rollback completed
  abort: pretxnclose-bookmark.force-public hook exited with status 1
  [255]

create on a public changeset

  $ hg bookmark -r 'max(public())' NEW

move to the other branch

  $ hg bookmark -f -r 125c9a1d6df6 NEW
