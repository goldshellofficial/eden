#chg-compatible
  $ setconfig experimental.allowfilepeer=True

  $ disable treemanifest
  $ setconfig remotenames.selectivepull=1
  $ setconfig remotefilelog.write-hgcache-to-indexedlog=False remotefilelog.write-local-to-indexedlog=False

  $ LFSPATH=$TESTTMP/lfs
  $ export LFSPATH
  $ mkdir $LFSPATH

  $ . "$TESTDIR/library.sh"

  $ hginit master
  $ cd master
  $ cat >> $HGRCPATH <<EOF
  > [extensions]
  > lfs=
  > [lfs]
  > url=file://$LFSPATH
  > verify=existance
  > EOF
  $ cat >> .hg/hgrc <<EOF
  > [remotefilelog]
  > server=True
  > EOF
  $ echo x > x
  $ echo z > z
  $ hg commit -qAm x
  $ echo x2 > x
  $ echo y > y
  $ hg commit -qAm y
  $ echo large > large
  $ hg --config 'lfs.threshold=1' commit -qAm y
  $ hg bookmark foo
  $ hg debuglfsupload -r tip

  $ cd ..

# prefetch a revision

  $ hgcloneshallowlfs ssh://user@dummy/master shallow file://$LFSPATH --noupdate
  fetching changelog
  3 files to transfer, * bytes of data (glob)
  transferred * bytes in * seconds (*) (glob)
  fetching selected remote bookmarks
  $ cd shallow

  $ hg prefetch -r 'desc(x)'
  2 files fetched over 1 fetches - (2 misses, 0.00% hit ratio) over *s (glob) (?)

  $ hg cat -r 'desc(x)' x
  x

# prefetch a range of revisions

  $ clearcache
  $ hg prefetch -r 'desc(x)'::109c3a557a73b62e762a1a928070e84f52c9e2c6
  4 files fetched over 1 fetches - (4 misses, 0.00% hit ratio) over *s (glob) (?)

  $ hg cat -r 'desc(x)' x
  x
  $ hg cat -r 109c3a557a73b62e762a1a928070e84f52c9e2c6 x
  x2

# prefetch certain files

  $ clearcache
  $ hg prefetch -r 109c3a557a73b62e762a1a928070e84f52c9e2c6 x
  1 files fetched over 1 fetches - (1 misses, 0.00% hit ratio) over *s (glob) (?)

  $ hg cat -r 109c3a557a73b62e762a1a928070e84f52c9e2c6 x
  x2

  $ hg cat -r 109c3a557a73b62e762a1a928070e84f52c9e2c6 y
  y
  1 files fetched over 1 fetches - (1 misses, 0.00% hit ratio) over *s (glob) (?)

# prefetch large file

  $ hg prefetch -r 'max(desc(y))'
  2 files fetched over 1 fetches - (2 misses, 0.00% hit ratio) over *s (glob) (?)

# prefetch on pull when configured

  $ printf "[remotefilelog]\npullprefetch=bookmark()\n" >> .hg/hgrc
  $ hg debugstrip tip

  $ clearcache
  $ hg pull
  pulling from ssh://user@dummy/master
  prefetching file contents
  4 files fetched over * fetches - (4 misses, 0.00% hit ratio) over *s (glob) (?)

  $ hg up tip
  3 files updated, 0 files merged, 0 files removed, 0 files unresolved
