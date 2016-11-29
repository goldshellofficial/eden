  $ . "$TESTDIR/library.sh"

  $ PYTHONPATH=$TESTDIR/..:$PYTHONPATH
  $ export PYTHONPATH

  $ hginit master
  $ cd master
  $ cat >> .hg/hgrc <<EOF
  > [remotefilelog]
  > server=True
  > EOF
  $ echo x > x
  $ hg commit -qAm 'add x'
  $ cd ..

  $ hgcloneshallow ssh://user@dummy/master client -q
  1 files fetched over 1 fetches - (1 misses, 0.00% hit ratio) over * (glob)
  $ cd client
  $ cat >> .hg/hgrc <<EOF
  > [extensions]
  > fastmanifest=
  > treemanifest=
  > 
  > [remotefilelog]
  > usefastdatapack=True
  > 
  > [fastmanifest]
  > usetree=True
  > usecache=False
  > EOF

Test autocreatetrees
  $ cat >> .hg/hgrc <<EOF
  > [treemanifest]
  > autocreatetrees=True
  > EOF
  $ cd ../master
  $ mkdir subdir
  $ echo z >> subdir/z
  $ hg commit -qAm 'add subdir/z'

  $ cd ../client
  $ hg pull
  pulling from ssh://user@dummy/master
  searching for changes
  adding changesets
  adding manifests
  adding file changes
  added 1 changesets with 0 changes to 0 files
  (run 'hg update' to get a working copy)
  $ ls -l $CACHEDIR/master/packs/manifests
  total * (glob)
  * 1146 * 61f86a9a8f327cb2d9928e5678665f9a6d26b3f9.dataidx (glob)
  *  354 * 61f86a9a8f327cb2d9928e5678665f9a6d26b3f9.datapack (glob)

  $ hg debugdatapack $CACHEDIR/master/packs/manifests/61f86a9a8f327cb2d9928e5678665f9a6d26b3f9
  
  
  Node          Delta Base    Delta Length
  bc0c2c938b92  000000000000  43
  
  subdir/
  Node          Delta Base    Delta Length
  ddb35f099a64  000000000000  43
  
  
  Node          Delta Base    Delta Length
  70f2c6726cec  000000000000  92

Test that commit creates local trees
  $ hg up -q tip
  1 files fetched over 1 fetches - (1 misses, 0.00% hit ratio) over * (glob)
  $ echo z >> subdir/z
  $ hg commit -qAm 'modify subdir/z'
  $ ls -l .hg/store/packs/manifests
  * (glob)
  * 1106 * 5ae421f7ddd38490fe5bb8fb379861746c7377d4.dataidx (glob)
  * 255 * 5ae421f7ddd38490fe5bb8fb379861746c7377d4.datapack (glob)
  $ hg debugdatapack .hg/store/packs/manifests/5ae421f7ddd38490fe5bb8fb379861746c7377d4
  
  subdir/
  Node          Delta Base    Delta Length
  ac728a786423  000000000000  43
  
  
  Node          Delta Base    Delta Length
  7a911436836f  000000000000  92
