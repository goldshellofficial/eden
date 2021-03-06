#chg-compatible
  $ enable convert
  $ setconfig convert.hg.saverev=False

  $ hg init orig
  $ cd orig
  $ echo foo > foo
  $ echo bar > bar
  $ hg ci -qAm 'add foo and bar'
  $ hg rm foo
  $ hg ci -m 'remove foo'
  $ mkdir foo
  $ echo file > foo/file
  $ hg ci -qAm 'add foo/file'
  $ hg log
  commit:      f17fa89f2ab1
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     add foo/file
  
  commit:      cbba8ecc03b7
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     remove foo
  
  commit:      327daa9251fa
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     add foo and bar
  
  $ hg bookmark main -r tip
  $ cd ..
  $ hg convert orig new 2>&1 | grep -v 'subversion python bindings could not be loaded'
  initializing destination new repository
  scanning source...
  sorting...
  converting...
  2 add foo and bar
  1 remove foo
  0 add foo/file
  updating bookmarks
  $ cd new
  $ hg log -G --template '{node|short} ({phase}) "{desc}"\n'
  o  f17fa89f2ab1 (draft) "add foo/file"
  │
  o  cbba8ecc03b7 (draft) "remove foo"
  │
  o  327daa9251fa (draft) "add foo and bar"
  

dirstate should be empty:

  $ hg debugstate
  $ hg parents -q
  $ hg up -C
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg copy bar baz

put something in the dirstate:

  $ hg debugstate > debugstate
  $ grep baz debugstate
  a   0         -1 unset               baz
  copy: bar -> baz

add a new revision in the original repo

  $ cd ../orig
  $ echo baz > baz
  $ hg ci -qAm 'add baz'
  $ cd ..
  $ hg convert orig new 2>&1 | grep -v 'subversion python bindings could not be loaded'
  scanning source...
  sorting...
  converting...
  0 add baz
  updating bookmarks
  $ cd new

dirstate should be the same (no output below):

  $ hg debugstate > new-debugstate
  $ diff debugstate new-debugstate

no copies

  $ hg up -C
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg debugrename baz
  baz not renamed
  $ cd ..

Test cases for hg-hg roundtrip

Helper

  $ glog()
  > {
  >     hg log -G --template '{node|short} ({phase}) "{desc}" files: {files}\n' $*
  > }

Create a tricky source repo

  $ hg init source
  $ cd source

  $ echo 0 > 0
  $ hg ci -Aqm '0: add 0'
  $ echo a > a
  $ mkdir dir
  $ echo b > dir/b
  $ hg ci -qAm '1: add a and dir/b'
  $ echo c > dir/c
  $ hg ci -qAm '2: add dir/c'
  $ hg copy a e
  $ echo b >> b
  $ hg ci -qAm '3: copy a to e, change b'
  $ hg up -qr -3
  $ echo a >> a
  $ hg ci -qAm '4: change a'
  $ hg merge
  merging a and e to e
  2 files updated, 1 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg copy b dir/d
  $ hg ci -qAm '5: merge 2 and 3, copy b to dir/d'
  $ echo a >> a
  $ hg ci -qAm '6: change a'

  $ hg mani
  0
  a
  b
  e
  dir/b
  dir/c
  dir/d
  $ hg bookmark main -r tip
  $ glog
  @  1867ad0849db (draft) "6: change a" files: a
  │
  o    72f28de01ce6 (draft) "5: merge 2 and 3, copy b to dir/d" files: dir/d e
  ├─╮
  │ o  f8a6227c8908 (draft) "4: change a" files: a
  │ │
  o │  998d5cc3a4a2 (draft) "3: copy a to e, change b" files: b e
  │ │
  o │  c339622f8a56 (draft) "2: add dir/c" files: dir/c
  ├─╯
  o  171bac3f503e (draft) "1: add a and dir/b" files: a dir/b
  │
  o  d1a24e2ebd23 (draft) "0: add 0" files: 0
  
  $ cd ..

Convert excluding rev 0 and dir/ (and thus rev2):

  $ cat << EOF > filemap
  > exclude dir
  > EOF

  $ hg convert --filemap filemap source dest --config convert.hg.revs=1::
  initializing destination dest repository
  scanning source...
  sorting...
  converting...
  5 1: add a and dir/b
  4 2: add dir/c
  3 3: copy a to e, change b
  2 4: change a
  1 5: merge 2 and 3, copy b to dir/d
  0 6: change a
  updating bookmarks

Verify that conversion skipped rev 2:

  $ glog -R dest
  o  78814e84a217 (draft) "6: change a" files: a
  │
  o    f7cff662c5e5 (draft) "5: merge 2 and 3, copy b to dir/d" files: e
  ├─╮
  │ o  ab40a95b0072 (draft) "4: change a" files: a
  │ │
  o │  bd51f17597bf (draft) "3: copy a to e, change b" files: b e
  ├─╯
  o  a4a1dae0fe35 (draft) "1: add a and dir/b" files: 0 a
  

Verify mapping correct in both directions:

  $ cat source/.hg/shamap
  a4a1dae0fe3514cefd9b8541b7abbc8f44f946d5 171bac3f503e5ef4584c0ef9e85c1fe1dbec6638
  bd51f17597bf32268e68a560b206898c3960cda2 998d5cc3a4a208d3bf4d12c38659098f6398560b
  ab40a95b00725307e79c2fd271000aa8af9759f4 f8a6227c8908f34d7c5c36e50e60414e3e78a85f
  f7cff662c5e581e6f3f1a85ffdd2bcb35825f6ba 72f28de01ce6b624bf0fefc6cb5bffb337af2626
  78814e84a217894517c2de392b903ed05e6871a4 1867ad0849db8749c5cd94b40b003a47638a277e
  $ cat dest/.hg/shamap
  171bac3f503e5ef4584c0ef9e85c1fe1dbec6638 a4a1dae0fe3514cefd9b8541b7abbc8f44f946d5
  c339622f8a5696ac469991db0d2e30317128d932 a4a1dae0fe3514cefd9b8541b7abbc8f44f946d5
  998d5cc3a4a208d3bf4d12c38659098f6398560b bd51f17597bf32268e68a560b206898c3960cda2
  f8a6227c8908f34d7c5c36e50e60414e3e78a85f ab40a95b00725307e79c2fd271000aa8af9759f4
  72f28de01ce6b624bf0fefc6cb5bffb337af2626 f7cff662c5e581e6f3f1a85ffdd2bcb35825f6ba
  1867ad0849db8749c5cd94b40b003a47638a277e 78814e84a217894517c2de392b903ed05e6871a4

Verify meta data converted correctly:

  $ hg -R dest log -r bd51f17597bf32268e68a560b206898c3960cda2 --debug -p --git
  commit:      bd51f17597bf32268e68a560b206898c3960cda2
  phase:       draft
  manifest:    040c72ed9b101773c24ac314776bfc846943781f
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  files+:      b e
  extra:       branch=default
  description:
  3: copy a to e, change b
  
  
  diff --git a/b b/b
  new file mode 100644
  --- /dev/null
  +++ b/b
  @@ -0,0 +1,1 @@
  +b
  diff --git a/a b/e
  copy from a
  copy to e
  
Verify files included and excluded correctly:

  $ hg -R dest manifest -r tip
  0
  a
  b
  e


Make changes in dest and convert back:

  $ hg -R dest up -q
  $ echo dest > dest/dest
  $ hg -R dest ci -Aqm 'change in dest'
  $ hg -R dest tip
  commit:      a2e0e3cc6d1d
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  summary:     change in dest
  

(converting merges back after using a filemap will probably cause chaos so we
exclude merges.)

  $ hg convert dest source --config convert.hg.revs='!merge()'
  scanning source...
  sorting...
  converting...
  0 change in dest
  updating bookmarks

Verify the conversion back:

  $ hg -R source log --debug -r tip
  commit:      e963ef84c4c280fc1779fc8377b9c88998462ac3
  phase:       draft
  manifest:    2f2830baf3f3c6de2b0eb3b1092ed3938b6dae94
  user:        test
  date:        Thu Jan 01 00:00:00 1970 +0000
  files+:      dest
  extra:       branch=default
  description:
  change in dest
  
  
Files that had been excluded are still present:

  $ hg -R source manifest -r tip
  0
  a
  b
  dest
  e
  dir/b
  dir/c
  dir/d

More source changes

  $ cd source
  $ echo 1 >> a
  $ hg ci -m '8: source first branch'
  $ hg up -qr -2
  $ echo 2 >> a
  $ hg ci -m '9: source second branch'
  $ hg merge -q --tool internal:local
  $ hg ci -m '10: source merge'
  $ echo >> a
  $ hg ci -m '11: source change'

  $ hg mani
  0
  a
  b
  dest
  e
  dir/b
  dir/c
  dir/d

  $ glog -r 6:
  @  9d8c6bc14c8a (draft) "11: source change" files: a
  │
  o    299eb2311d0f (draft) "10: source merge" files: a
  ├─╮
  │ o  4fab9b4bb9ad (draft) "9: source second branch" files: a
  │ │
  o │  e1dc5ae7f55e (draft) "8: source first branch" files: a
  │ │
  │ o  e963ef84c4c2 (draft) "change in dest" files: dest
  ├─╯
  o  1867ad0849db (draft) "6: change a" files: a
  │
  ~
  $ cd ..

  $ hg convert --filemap filemap source dest --config convert.hg.revs=3:
  scanning source...
  sorting...
  converting...
  3 8: source first branch
  2 9: source second branch
  1 10: source merge
  0 11: source change
  updating bookmarks

  $ glog -R dest
  o  8432d597b263 (draft) "11: source change" files: a
  │
  o    632ffacdcd6f (draft) "10: source merge" files: a
  ├─╮
  │ o  049cfee90ee6 (draft) "9: source second branch" files: a
  │ │
  o │  9b6845e036e5 (draft) "8: source first branch" files: a
  │ │
  │ @  a2e0e3cc6d1d (draft) "change in dest" files: dest
  ├─╯
  o  78814e84a217 (draft) "6: change a" files: a
  │
  o    f7cff662c5e5 (draft) "5: merge 2 and 3, copy b to dir/d" files: e
  ├─╮
  │ o  ab40a95b0072 (draft) "4: change a" files: a
  │ │
  o │  bd51f17597bf (draft) "3: copy a to e, change b" files: b e
  ├─╯
  o  a4a1dae0fe35 (draft) "1: add a and dir/b" files: 0 a
  
  $ cd ..

Two way tests

  $ hg init 0
  $ echo f > 0/f
  $ echo a > 0/a-only
  $ echo b > 0/b-only
  $ hg -R 0 ci -Aqm0

  $ cat << EOF > filemap-a
  > exclude b-only
  > EOF
  $ cat << EOF > filemap-b
  > exclude a-only
  > EOF
  $ hg convert --filemap filemap-a 0 a
  initializing destination a repository
  scanning source...
  sorting...
  converting...
  0 0
  $ hg -R a up -q
  $ echo a > a/f
  $ hg -R a ci -ma

  $ hg convert --filemap filemap-b 0 b
  initializing destination b repository
  scanning source...
  sorting...
  converting...
  0 0
  $ hg -R b up -q
  $ echo b > b/f
  $ hg -R b ci -mb

  $ tail 0/.hg/shamap
  86f3f774ffb682bffb5dc3c1d3b3da637cb9a0d6 8a028c7c77f6c7bd6d63bc3f02ca9f779eabf16a
  dd9f218eb91fb857f2a62fe023e1d64a4e7812fe 8a028c7c77f6c7bd6d63bc3f02ca9f779eabf16a
  $ tail a/.hg/shamap
  8a028c7c77f6c7bd6d63bc3f02ca9f779eabf16a 86f3f774ffb682bffb5dc3c1d3b3da637cb9a0d6
  $ tail b/.hg/shamap
  8a028c7c77f6c7bd6d63bc3f02ca9f779eabf16a dd9f218eb91fb857f2a62fe023e1d64a4e7812fe

  $ hg convert a 0
  scanning source...
  sorting...
  converting...
  0 a

  $ hg convert b 0
  scanning source...
  sorting...
  converting...
  0 b

  $ hg -R 0 log -G
  o  commit:      637fbbbe96b6
  │  user:        test
  │  date:        Thu Jan 01 00:00:00 1970 +0000
  │  summary:     b
  │
  │ o  commit:      ec7b9c96e692
  ├─╯  user:        test
  │    date:        Thu Jan 01 00:00:00 1970 +0000
  │    summary:     a
  │
  @  commit:      8a028c7c77f6
     user:        test
     date:        Thu Jan 01 00:00:00 1970 +0000
     summary:     0
  
  $ hg convert --filemap filemap-b 0 a --config convert.hg.revs=1::
  scanning source...
  sorting...
  converting...

  $ hg -R 0 up -r'desc(a)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo f >> 0/f
  $ hg -R 0 ci -mx

  $ hg convert --filemap filemap-b 0 a --config convert.hg.revs=1::
  scanning source...
  sorting...
  converting...
  0 x

  $ hg -R a log -G -T '{desc|firstline} ({files})\n'
  o  x (f)
  │
  @  a (f)
  │
  o  0 (a-only f)
  
  $ hg -R a mani -r tip
  a-only
  f

An additional round, demonstrating that unchanged files don't get converted

  $ echo f >> 0/f
  $ echo f >> 0/a-only
  $ hg -R 0 ci -m "extra f+a-only change"

  $ hg convert --filemap filemap-b 0 a --config convert.hg.revs=1::
  scanning source...
  sorting...
  converting...
  0 extra f+a-only change

  $ hg -R a log -G -T '{desc|firstline} ({files})\n'
  o  extra f+a-only change (f)
  │
  o  x (f)
  │
  @  a (f)
  │
  o  0 (a-only f)
  

Convert with --full adds and removes files that didn't change

  $ echo f >> 0/f
  $ hg -R 0 ci -m "f"
  $ hg convert --filemap filemap-b --full 0 a --config convert.hg.revs=1::
  scanning source...
  sorting...
  converting...
  0 f
  $ hg -R a status --change tip
  M f
  A b-only
  R a-only
