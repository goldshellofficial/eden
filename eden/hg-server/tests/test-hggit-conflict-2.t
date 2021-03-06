Load commonly used test logic
  $ . "$TESTDIR/hggit/testutil"

  $ hg init hgrepo1
  $ cd hgrepo1
  $ echo A > afile
  $ hg add afile
  $ hg ci -m "origin"

  $ echo B > afile
  $ hg ci -m "A->B"

  $ hg up -r'desc(origin)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo C > afile
  $ hg ci -m "A->C"

  $ hg merge -r7205e83b5a3fb01334c76fef35a69c912f5b2ba3
  merging afile
  warning: 1 conflicts while merging afile! (edit, then use 'hg resolve --mark')
  0 files updated, 0 files merged, 0 files removed, 1 files unresolved
  use 'hg resolve' to retry unresolved file merges or 'hg update -C .' to abandon
  [1]
resolve using second parent
  $ echo B > afile
  $ hg resolve -m afile | egrep -v 'no more unresolved files' || true
  $ hg ci -m "merge to B"

  $ hg log --graph --style compact
  @       120385945d08   1970-01-01 00:00 +0000   test
  ├─╮    merge to B
  │ │
  │ o     ea82b67264a1   1970-01-01 00:00 +0000   test
  │ │    A->C
  │ │
  o │     7205e83b5a3f   1970-01-01 00:00 +0000   test
  ├─╯    A->B
  │
  o     5d1a6b64f9d0   1970-01-01 00:00 +0000   test
       origin
  

  $ cd ..

  $ git init -q --bare gitrepo

  $ cd hgrepo1
  $ hg bookmark -r tip master
  $ hg push -r master ../gitrepo
  pushing to ../gitrepo
  searching for changes
  adding objects
  added 4 commits with 3 trees and 3 blobs
  $ cd ..

  $ hg clone gitrepo hgrepo2 | grep -v '^updating'
  importing git objects into hg
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
expect the same revision ids as above
  $ hg -R hgrepo2 log --graph --style compact
  @    [master]   df42911f11c1   1970-01-01 00:00 +0000   test
  ├─╮    merge to B
  │ │
  │ o     47fc555571b8   1970-01-01 00:00 +0000   test
  │ │    A->B
  │ │
  o │     8ec5b459b86e   1970-01-01 00:00 +0000   test
  ├─╯    A->C
  │
  o     fd5eb788c3a1   1970-01-01 00:00 +0000   test
       origin
  
