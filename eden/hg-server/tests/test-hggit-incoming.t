Load commonly used test logic
  $ . "$TESTDIR/hggit/testutil"
  $ disable treemanifest

  $ git init -q gitrepo
  $ cd gitrepo
  $ echo alpha > alpha
  $ git add alpha
  $ fn_git_commit -m "add alpha"

  $ cd ..
  $ hg init hgrepo-empty
  $ hg -R hgrepo-empty incoming gitrepo 2>&1 | grep -v 'no changes found'
  comparing with gitrepo
  commit:      7eeab2ea75ec
  bookmark:    master
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:10 2007 +0000
  summary:     add alpha
  

  $ hg clone gitrepo hgrepo 2>&1 | grep -v '^updating'
  importing git objects into hg
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved

  $ hg -R hgrepo incoming 2>&1 | grep -v 'no changes found'
  comparing with $TESTTMP/gitrepo

  $ cd gitrepo
  $ echo beta > beta
  $ git add beta
  $ fn_git_commit -m 'add beta'
  $ cd ..

  $ hg -R hgrepo incoming 2>&1 | grep -v 'no changes found'
  comparing with $TESTTMP/gitrepo
  commit:      9497a4ee62e1
  bookmark:    master
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:11 2007 +0000
  summary:     add beta
  

  $ cd gitrepo
  $ git checkout -b b1 'HEAD^'
  Switched to a new branch 'b1'
  $ mkdir d
  $ echo gamma > d/gamma
  $ git add d/gamma
  $ fn_git_commit -m'add d/gamma'
  $ git tag t1

  $ echo gamma 2 >> d/gamma
  $ git add d/gamma
  $ fn_git_commit -m'add d/gamma line 2'
  $ cd ../hgrepo
  $ hg incoming -p 2>&1 | grep -v 'no changes found'
  comparing with $TESTTMP/gitrepo
  commit:      9497a4ee62e1
  bookmark:    master
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:11 2007 +0000
  summary:     add beta
  
  diff -r 69982ec78c6d -r 9497a4ee62e1 beta
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/beta	Mon Jan 01 00:00:11 2007 +0000
  @@ -0,0 +1,1 @@
  +beta
  
  commit:      9865e289be73
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:12 2007 +0000
  summary:     add d/gamma
  
  diff -r 69982ec78c6d -r 9865e289be73 d/gamma
  --- /dev/null	Thu Jan 01 00:00:00 1970 +0000
  +++ b/d/gamma	Mon Jan 01 00:00:12 2007 +0000
  @@ -0,0 +1,1 @@
  +gamma
  
  commit:      5202f48c20c9
  bookmark:    b1
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:13 2007 +0000
  summary:     add d/gamma line 2
  
  diff -r 9865e289be73 -r 5202f48c20c9 d/gamma
  --- a/d/gamma	Mon Jan 01 00:00:12 2007 +0000
  +++ b/d/gamma	Mon Jan 01 00:00:13 2007 +0000
  @@ -1,1 +1,2 @@
   gamma
  +gamma 2
  

incoming -r
  $ hg incoming -r master 2>&1 | grep -v 'no changes found'
  comparing with $TESTTMP/gitrepo
  commit:      9497a4ee62e1
  bookmark:    master
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:11 2007 +0000
  summary:     add beta
  
  $ hg incoming -r b1 2>&1 | grep -v 'no changes found'
  comparing with $TESTTMP/gitrepo
  commit:      9865e289be73
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:12 2007 +0000
  summary:     add d/gamma
  
  commit:      5202f48c20c9
  bookmark:    b1
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:13 2007 +0000
  summary:     add d/gamma line 2
  
  $ hg incoming -r t1 2>&1 | grep -v 'no changes found'
  comparing with $TESTTMP/gitrepo
  commit:      9865e289be73
  user:        test <test@example.org>
  date:        Mon Jan 01 00:00:12 2007 +0000
  summary:     add d/gamma
  

nothing incoming after pull
"adding remote bookmark" message was added in Mercurial 2.3
  $ hg pull 2>&1 | grep -v "adding remote bookmark"
  pulling from $TESTTMP/gitrepo
  importing git objects into hg
  $ hg incoming 2>&1 | grep -v 'no changes found'
  comparing with $TESTTMP/gitrepo
