#chg-compatible

  $ disable treemanifest

  $ HGMERGE=true; export HGMERGE
  $ echo '[extensions]' >> $HGRCPATH
  $ echo 'convert =' >> $HGRCPATH
  $ glog()
  > {
  >     hg log -G --template '"{desc}" files: {files}\n' "$@"
  > }
  $ hg init source
  $ cd source
  $ echo foo > foo
  $ echo baz > baz
  $ mkdir -p dir/subdir
  $ echo dir/file >> dir/file
  $ echo dir/file2 >> dir/file2
  $ echo dir/file3 >> dir/file3 # to be corrupted in rev 0
  $ echo dir/subdir/file3 >> dir/subdir/file3
  $ echo dir/subdir/file4 >> dir/subdir/file4
  $ hg ci -d '0 0' -qAm '0: add foo baz dir/'
  $ echo bar > bar
  $ echo quux > quux
  $ echo dir/file4 >> dir/file4 # to be corrupted in rev 1
  $ hg copy foo copied
  $ hg ci -d '1 0' -qAm '1: add bar quux; copy foo to copied'
  $ echo >> foo
  $ hg ci -d '2 0' -m '2: change foo'
  $ hg up -qC 61e22ca76c3b3e93df20338c4e02ce286898e825
  $ echo >> bar
  $ echo >> quux
  $ hg ci -d '3 0' -m '3: change bar quux'
  $ hg up -qC 59e1ab45c888289513b7354484dac8a88217beab
  $ hg merge -qr af455ce4166b3c9c88e6309c2b9332171dcea595
  $ echo >> bar
  $ echo >> baz
  $ hg ci -d '4 0' -m '4: first merge; change bar baz'
  $ echo >> bar
  $ echo 1 >> baz
  $ echo >> quux
  $ hg ci -d '5 0' -m '5: change bar baz quux'
  $ hg up -qC cf908b3eeedc301c9272ebae931da966d5b326c7
  $ echo >> foo
  $ echo 2 >> baz
  $ hg ci -d '6 0' -m '6: change foo baz'
  $ hg up -qC 34a3d65699bfbc2d97d2c85929e1798ea6cebc62
  $ hg merge -qr df0642fe0a049507246c5572234aebb5b1b8356a
  $ echo >> bar
  $ hg ci -d '7 0' -m '7: second merge; change bar'
  $ echo >> foo
  $ hg ci -m '8: change foo'
  $ glog
  @  "8: change foo" files: foo
  │
  o    "7: second merge; change bar" files: bar baz
  ├─╮
  │ o  "6: change foo baz" files: baz foo
  │ │
  o │  "5: change bar baz quux" files: bar baz quux
  ├─╯
  o    "4: first merge; change bar baz" files: bar baz
  ├─╮
  │ o  "3: change bar quux" files: bar quux
  │ │
  o │  "2: change foo" files: foo
  ├─╯
  o  "1: add bar quux; copy foo to copied" files: bar copied dir/file4 quux
  │
  o  "0: add foo baz dir/" files: baz dir/file dir/file2 dir/file3 dir/subdir/file3 dir/subdir/file4 foo
  

final file versions in this repo:

  $ hg manifest --debug
  9463f52fe115e377cf2878d4fc548117211063f2 644   bar
  94c1be4dfde2ee8d78db8bbfcf81210813307c3d 644   baz
  7711d36246cc83e61fb29cd6d4ef394c63f1ceaf 644   copied
  3e20847584beff41d7cd16136b7331ab3d754be0 644   dir/file
  75e6d3f8328f5f6ace6bf10b98df793416a09dca 644   dir/file2
  e96dce0bc6a217656a3a410e5e6bec2c4f42bf7c 644   dir/file3
  6edd55f559cdce67132b12ca09e09cee08b60442 644   dir/file4
  5fe139720576e18e34bcc9f79174db8897c8afe9 644   dir/subdir/file3
  57a1c1511590f3de52874adfa04effe8a77d64af 644   dir/subdir/file4
  9a7b52012991e4873687192c3e17e61ba3e837a3 644   foo
  bc3eca3f47023a3e70ca0d8cc95a22a6827db19d 644   quux
  $ hg debugrename copied
  copied renamed from foo:2ed2a3912a0b24502043eae84ee4b279c18b90dd

  $ cd ..


Test interaction with startrev and verify that changing it is handled properly:

  $ > empty
  $ hg convert --filemap empty source movingstart --config convert.hg.startrev=3 -r4
  initializing destination movingstart repository
  scanning source...
  sorting...
  converting...
  1 3: change bar quux
  0 4: first merge; change bar baz
  $ hg convert --filemap empty source movingstart
  scanning source...
  sorting...
  converting...
  3 5: change bar baz quux
  2 6: change foo baz
  1 7: second merge; change bar
  warning: af455ce4166b3c9c88e6309c2b9332171dcea595 parent 61e22ca76c3b3e93df20338c4e02ce286898e825 is missing
  warning: cf908b3eeedc301c9272ebae931da966d5b326c7 parent 59e1ab45c888289513b7354484dac8a88217beab is missing
  0 8: change foo


splitrepo tests

  $ splitrepo()
  > {
  >     msg="$1"
  >     files="$2"
  >     opts=$3
  >     echo "% $files: $msg"
  >     prefix=`echo "$files" | sed -e 's/ /-/g'`
  >     fmap="$prefix.fmap"
  >     repo="$prefix.repo"
  >     for i in $files; do
  >         echo "include $i" >> "$fmap"
  >     done
  >     hg -q convert $opts --filemap "$fmap" --datesort source "$repo"
  >     hg up -q -R "$repo"
  >     glog -R "$repo"
  >     hg -R "$repo" manifest --debug
  > }
  $ splitrepo 'skip unwanted merges; use 1st parent in 1st merge, 2nd in 2nd' foo
  % foo: skip unwanted merges; use 1st parent in 1st merge, 2nd in 2nd
  @  "8: change foo" files: foo
  │
  o  "6: change foo baz" files: foo
  │
  o  "2: change foo" files: foo
  │
  o  "0: add foo baz dir/" files: foo
  
  9a7b52012991e4873687192c3e17e61ba3e837a3 644   foo
  $ splitrepo 'merges are not merges anymore' bar
  % bar: merges are not merges anymore
  @  "7: second merge; change bar" files: bar
  │
  o  "5: change bar baz quux" files: bar
  │
  o  "4: first merge; change bar baz" files: bar
  │
  o  "3: change bar quux" files: bar
  │
  o  "1: add bar quux; copy foo to copied" files: bar
  
  9463f52fe115e377cf2878d4fc548117211063f2 644   bar
  $ splitrepo '1st merge is not a merge anymore; 2nd still is' baz
  % baz: 1st merge is not a merge anymore; 2nd still is
  @    "7: second merge; change bar" files: baz
  ├─╮
  │ o  "6: change foo baz" files: baz
  │ │
  o │  "5: change bar baz quux" files: baz
  ├─╯
  o  "4: first merge; change bar baz" files: baz
  │
  o  "0: add foo baz dir/" files: baz
  
  94c1be4dfde2ee8d78db8bbfcf81210813307c3d 644   baz
  $ splitrepo 'we add additional merges when they are interesting' 'foo quux'
  % foo quux: we add additional merges when they are interesting
  @  "8: change foo" files: foo
  │
  o    "7: second merge; change bar" files:
  ├─╮
  │ o  "6: change foo baz" files: foo
  │ │
  o │  "5: change bar baz quux" files: quux
  ├─╯
  o    "4: first merge; change bar baz" files:
  ├─╮
  │ o  "3: change bar quux" files: quux
  │ │
  o │  "2: change foo" files: foo
  ├─╯
  o  "1: add bar quux; copy foo to copied" files: quux
  │
  o  "0: add foo baz dir/" files: foo
  
  9a7b52012991e4873687192c3e17e61ba3e837a3 644   foo
  bc3eca3f47023a3e70ca0d8cc95a22a6827db19d 644   quux
  $ splitrepo 'partial conversion' 'bar quux' '-r 3'
  % bar quux: partial conversion
  @  "3: change bar quux" files: bar quux
  │
  o  "1: add bar quux; copy foo to copied" files: bar quux
  
  b79105bedc55102f394e90a789c9c380117c1b4a 644   bar
  db0421cc6b685a458c8d86c7d5c004f94429ea23 644   quux
  $ splitrepo 'complete the partial conversion' 'bar quux'
  % bar quux: complete the partial conversion
  @  "7: second merge; change bar" files: bar
  │
  o  "5: change bar baz quux" files: bar quux
  │
  o  "4: first merge; change bar baz" files: bar
  │
  o  "3: change bar quux" files: bar quux
  │
  o  "1: add bar quux; copy foo to copied" files: bar quux
  
  9463f52fe115e377cf2878d4fc548117211063f2 644   bar
  bc3eca3f47023a3e70ca0d8cc95a22a6827db19d 644   quux
  $ rm -r foo.repo
  $ splitrepo 'partial conversion' 'foo' '-r 3'
  % foo: partial conversion
  @  "0: add foo baz dir/" files: foo
  
  2ed2a3912a0b24502043eae84ee4b279c18b90dd 644   foo
  $ splitrepo 'complete the partial conversion' 'foo'
  % foo: complete the partial conversion
  @  "8: change foo" files: foo
  │
  o  "6: change foo baz" files: foo
  │
  o  "2: change foo" files: foo
  │
  o  "0: add foo baz dir/" files: foo
  
  9a7b52012991e4873687192c3e17e61ba3e837a3 644   foo
  $ splitrepo 'copied file; source not included in new repo' copied
  % copied: copied file; source not included in new repo
  @  "1: add bar quux; copy foo to copied" files: copied
  
  2ed2a3912a0b24502043eae84ee4b279c18b90dd 644   copied
  $ hg --cwd copied.repo debugrename copied
  copied not renamed
  $ splitrepo 'copied file; source included in new repo' 'foo copied'
  % foo copied: copied file; source included in new repo
  @  "8: change foo" files: foo
  │
  o  "6: change foo baz" files: foo
  │
  o  "2: change foo" files: foo
  │
  o  "1: add bar quux; copy foo to copied" files: copied
  │
  o  "0: add foo baz dir/" files: foo
  
  7711d36246cc83e61fb29cd6d4ef394c63f1ceaf 644   copied
  9a7b52012991e4873687192c3e17e61ba3e837a3 644   foo
  $ hg --cwd foo-copied.repo debugrename copied
  copied renamed from foo:2ed2a3912a0b24502043eae84ee4b279c18b90dd

verify the top level 'include .' if there is no other includes:

  $ echo "exclude something" > default.fmap
  $ hg convert -q --filemap default.fmap -r1 source dummydest2
  $ hg -R dummydest2 log --template '{node|short} {desc|firstline}\n'
  61e22ca76c3b 1: add bar quux; copy foo to copied
  c085cf2ee7fe 0: add foo baz dir/

  $ echo "include somethingelse" >> default.fmap
  $ hg convert -q --filemap default.fmap -r1 source dummydest3
  $ hg -R dummydest3 log --template '{node|short} {desc|firstline}\n'

  $ echo "include ." >> default.fmap
  $ hg convert -q --filemap default.fmap -r1 source dummydest4
  $ hg -R dummydest4 log --template '{node|short} {desc|firstline}\n'
  61e22ca76c3b 1: add bar quux; copy foo to copied
  c085cf2ee7fe 0: add foo baz dir/

ensure that the filemap contains duplicated slashes (issue3612)

  $ cat > renames.fmap <<EOF
  > include dir
  > exclude dir/file2
  > rename dir dir2//dir3
  > include foo
  > include copied
  > rename foo foo2/
  > rename copied ./copied2
  > exclude dir/subdir
  > include dir/subdir/file3
  > EOF
  $ rm source/.hg/store/data/dir/file3.i
  $ rm source/.hg/store/data/dir/file4.i
  $ hg -q convert --filemap renames.fmap --datesort source dummydest
  abort: data/dir/file3.i@e96dce0bc6a2: no match found!
  [255]
  $ hg -q convert --filemap renames.fmap --datesort --config convert.hg.ignoreerrors=1 source renames.repo
  ignoring: data/dir/file3.i@e96dce0bc6a2: no match found
  ignoring: data/dir/file4.i@6edd55f559cd: no match found
  $ hg up -q -R renames.repo
  $ glog -R renames.repo
  @  "8: change foo" files: foo2
  │
  o  "6: change foo baz" files: foo2
  │
  o  "2: change foo" files: foo2
  │
  o  "1: add bar quux; copy foo to copied" files: copied2
  │
  o  "0: add foo baz dir/" files: dir2/dir3/file dir2/dir3/subdir/file3 foo2
  
  $ hg -R renames.repo verify
  warning: verify does not actually check anything in this repo

  $ hg -R renames.repo manifest --debug
  d43feacba7a4f1f2080dde4a4b985bd8a0236d46 644   copied2
  3e20847584beff41d7cd16136b7331ab3d754be0 644   dir2/dir3/file
  5fe139720576e18e34bcc9f79174db8897c8afe9 644   dir2/dir3/subdir/file3
  9a7b52012991e4873687192c3e17e61ba3e837a3 644   foo2
  $ hg --cwd renames.repo debugrename copied2
  copied2 renamed from foo2:2ed2a3912a0b24502043eae84ee4b279c18b90dd

copied:

  $ hg --cwd source cat copied
  foo

copied2:

  $ hg --cwd renames.repo cat copied2
  foo

filemap errors

  $ cat > errors.fmap <<EOF
  > include dir/ # beware that comments changes error line numbers!
  > exclude /dir
  > rename dir//dir /dir//dir/ "out of sync"
  > include
  > EOF
  $ hg -q convert --filemap errors.fmap source errors.repo
  errors.fmap:3: superfluous / in include '/dir'
  errors.fmap:3: superfluous / in rename '/dir'
  errors.fmap:4: unknown directive 'out of sync'
  errors.fmap:5: path to exclude is missing
  abort: errors in filemap
  [255]

filemap rename undoing revision rename

  $ hg init renameundo
  $ cd renameundo
  $ echo 1 > a
  $ echo 1 > c
  $ hg ci -qAm add
  $ hg mv -q a b/a
  $ hg mv -q c b/c
  $ hg ci -qm rename
  $ echo 2 > b/a
  $ echo 2 > b/c
  $ hg ci -qm modify
  $ cd ..

  $ echo "rename b ." > renameundo.fmap
  $ hg convert --filemap renameundo.fmap renameundo renameundo2
  initializing destination renameundo2 repository
  scanning source...
  sorting...
  converting...
  2 add
  1 rename
  filtering out empty revision
  repository tip rolled back to revision 0 (undo convert)
  0 modify
  $ glog -R renameundo2
  o  "modify" files: a c
  │
  │ o  "rename" files:
  ├─╯
  o  "add" files: a c
  


test merge parents/empty merges pruning

  $ glog()
  > {
  >     hg log -G --template '{node|short}@{branch} "{desc}" files: {files}\n' "$@"
  > }

test anonymous branch pruning

  $ hg init anonymousbranch
  $ cd anonymousbranch
  $ echo a > a
  $ echo b > b
  $ hg ci -Am add
  adding a
  adding b
  $ echo a >> a
  $ hg ci -m changea
  $ hg up 'desc(add)'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ echo b >> b
  $ hg ci -m changeb
  $ hg up 'desc(changea)'
  2 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg merge
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ hg ci -m merge
  $ cd ..

  $ cat > filemap <<EOF
  > include a
  > EOF
  $ hg convert --filemap filemap anonymousbranch anonymousbranch-hg
  initializing destination anonymousbranch-hg repository
  scanning source...
  sorting...
  converting...
  3 add
  2 changea
  1 changeb
  0 merge
  $ glog -R anonymousbranch
  @    c71d5201a498@default "merge" files:
  ├─╮
  │ o  607eb44b17f9@default "changeb" files: b
  │ │
  o │  1f60ea617824@default "changea" files: a
  ├─╯
  o  0146e6129113@default "add" files: a b
  
  $ glog -R anonymousbranch-hg
  o  cda818e7219b@default "changea" files: a
  │
  o  c334dc3be0da@default "add" files: a
  
  $ cat anonymousbranch-hg/.hg/shamap
  0146e6129113dba9ac90207cfdf2d7ed35257ae5 c334dc3be0daa2a4e9ce4d2e2bdcba40c09d4916
  1f60ea61782421edf8d051ff4fcb61b330f26a4a cda818e7219b5f7f3fb9f49780054ed6a1905ec3
  607eb44b17f9348cd5cbd26e16af87ba77b0b037 c334dc3be0daa2a4e9ce4d2e2bdcba40c09d4916
  c71d5201a498b2658d105a6bf69d7a0df2649aea cda818e7219b5f7f3fb9f49780054ed6a1905ec3

  $ cat > filemap <<EOF
  > include b
  > EOF
  $ hg convert --filemap filemap anonymousbranch anonymousbranch-hg2
  initializing destination anonymousbranch-hg2 repository
  scanning source...
  sorting...
  converting...
  3 add
  2 changea
  1 changeb
  0 merge
  $ glog -R anonymousbranch
  @    c71d5201a498@default "merge" files:
  ├─╮
  │ o  607eb44b17f9@default "changeb" files: b
  │ │
  o │  1f60ea617824@default "changea" files: a
  ├─╯
  o  0146e6129113@default "add" files: a b
  
  $ glog -R anonymousbranch-hg2
  o  62dd350b0df6@default "changeb" files: b
  │
  o  4b9ced861657@default "add" files: b
  
  $ cat anonymousbranch-hg2/.hg/shamap
  0146e6129113dba9ac90207cfdf2d7ed35257ae5 4b9ced86165703791653059a1db6ed864630a523
  1f60ea61782421edf8d051ff4fcb61b330f26a4a 4b9ced86165703791653059a1db6ed864630a523
  607eb44b17f9348cd5cbd26e16af87ba77b0b037 62dd350b0df695f7d2c82a02e0499b16fd790f22
  c71d5201a498b2658d105a6bf69d7a0df2649aea 62dd350b0df695f7d2c82a02e0499b16fd790f22

test converting merges into a repo that contains other files

  $ hg init merge-test1
  $ cd merge-test1
  $ touch a && hg commit -Aqm 'add a'
  $ echo a > a && hg commit -Aqm 'edit a'
  $ hg up -q 'desc(add)'
  $ touch b && hg commit -Aqm 'add b'
  $ hg merge -q 1 && hg commit -qm 'merge a & b'

  $ cd ..
  $ hg init merge-test2
  $ cd merge-test2
  $ mkdir converted
  $ touch converted/a toberemoved && hg commit -Aqm 'add converted/a & toberemoved'
  $ touch x && rm toberemoved && hg commit -Aqm 'add x & remove tobremoved'
  $ cd ..
  $ hg log -G -T '{shortest(node)} {desc}' -R merge-test1
  @    1191 merge a & b
  ├─╮
  │ o  9077 add b
  │ │
  o │  d19f edit a
  ├─╯
  o  ac82 add a
  
  $ hg log -G -T '{shortest(node)} {desc}' -R merge-test2
  @  150e add x & remove tobremoved
  │
  o  bbac add converted/a & toberemoved
  
- Build a shamap where the target converted/a is in on top of an unrelated
- change to 'x'. This simulates using convert to merge several repositories
- together.
  $ cat >> merge-test2/.hg/shamap <<EOF
  > $(hg -R merge-test1 log -r 0 -T '{node}') $(hg -R merge-test2 log -r 0 -T '{node}')
  > $(hg -R merge-test1 log -r 1 -T '{node}') $(hg -R merge-test2 log -r 1 -T '{node}')
  > EOF
  $ cat >> merge-test-filemap <<EOF
  > rename . converted/
  > EOF
  $ hg convert --filemap merge-test-filemap merge-test1 merge-test2 --traceback
  scanning source...
  sorting...
  converting...
  1 add b
  0 merge a & b
  $ hg -R merge-test2 manifest -r tip
  converted/a
  converted/b
  x
  $ hg -R merge-test2 log -G -T '{shortest(node)} {desc}\n{files % "- {file}\n"}\n'
  o    6eaa merge a & b
  ├─╮  - converted/a
  │ │  - toberemoved
  │ │
  │ o  2995 add b
  │ │  - converted/b
  │ │
  @ │  150e add x & remove tobremoved
  ├─╯  - toberemoved
  │    - x
  │
  o  bbac add converted/a & toberemoved
     - converted/a
     - toberemoved
  
  $ cd ..

Test case where cleanp2 contains a file that doesn't exist in p2 - for
example because filemap changed.

  $ hg init cleanp2
  $ cd cleanp2
  $ touch f f1 f2 && hg ci -Aqm '0'
  $ echo f1 > f1 && echo >> f && hg ci -m '1'
  $ hg up -qr'desc(0)' && echo f2 > f2 && echo >> f && hg ci -qm '2'
  $ echo "include f" > filemap
  $ hg convert --filemap filemap .
  assuming destination .-hg
  initializing destination .-hg repository
  scanning source...
  sorting...
  converting...
  2 0
  1 1
  0 2
  $ hg merge && hg ci -qm '3'
  1 files updated, 0 files merged, 0 files removed, 0 files unresolved
  (branch merge, don't forget to commit)
  $ echo "include ." > filemap
  $ hg convert --filemap filemap .
  assuming destination .-hg
  scanning source...
  sorting...
  converting...
  0 3
  $ hg -R .-hg log -G -T '{shortest(node)} {desc}\n{files % "- {file}\n"}\n'
  o    bbfe 3
  ├─╮
  │ o  33a0 2
  │ │  - f
  │ │
  o │  f73e 1
  ├─╯  - f
  │
  o  d681 0
     - f
  
  $ hg -R .-hg mani -r tip
  f
  $ cd ..
