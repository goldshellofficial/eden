# Portions Copyright (c) Facebook, Inc. and its affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

# Copyright 2010 Mercurial Contributors
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

"""automatically manage newlines in repository files

This extension allows you to manage the type of line endings (CRLF or
LF) that are used in the repository and in the local working
directory. That way you can get CRLF line endings on Windows and LF on
Unix/Mac, thereby letting everybody use their OS native line endings.

The extension reads its configuration from a versioned ``.hgeol``
configuration file found in the root of the working directory. The
``.hgeol`` file use the same syntax as all other Mercurial
configuration files. It uses two sections, ``[patterns]`` and
``[repository]``.

The ``[patterns]`` section specifies how line endings should be
converted between the working directory and the repository. The format is
specified by a file pattern. The first match is used, so put more
specific patterns first. The available line endings are ``LF``,
``CRLF``, and ``BIN``.

Files with the declared format of ``CRLF`` or ``LF`` are always
checked out and stored in the repository in that format and files
declared to be binary (``BIN``) are left unchanged. Additionally,
``native`` is an alias for checking out in the platform's default line
ending: ``LF`` on Unix (including Mac OS X) and ``CRLF`` on
Windows. Note that ``BIN`` (do nothing to line endings) is Mercurial's
default behavior; it is only needed if you need to override a later,
more general pattern.

The optional ``[repository]`` section specifies the line endings to
use for files stored in the repository. It has a single setting,
``native``, which determines the storage line endings for files
declared as ``native`` in the ``[patterns]`` section. It can be set to
``LF`` or ``CRLF``. The default is ``LF``. For example, this means
that on Windows, files configured as ``native`` (``CRLF`` by default)
will be converted to ``LF`` when stored in the repository. Files
declared as ``LF``, ``CRLF``, or ``BIN`` in the ``[patterns]`` section
are always stored as-is in the repository.

Example versioned ``.hgeol`` file::

  [patterns]
  **.py = native
  **.vcproj = CRLF
  **.txt = native
  Makefile = LF
  **.jpg = BIN

  [repository]
  native = LF

.. note::

   The rules will first apply when files are touched in the working
   directory, e.g. by updating to null and back to tip to touch all files.

The extension uses an optional ``[eol]`` section read from both the
normal Mercurial configuration files and the ``.hgeol`` file, with the
latter overriding the former. You can use that section to control the
overall behavior. There are three settings:

- ``eol.native`` (default ``os.linesep``) can be set to ``LF`` or
  ``CRLF`` to override the default interpretation of ``native`` for
  checkout. This can be used with :hg:`archive` on Unix, say, to
  generate an archive where files have line endings for Windows.

- ``eol.only-consistent`` (default True) can be set to False to make
  the extension convert files with inconsistent EOLs. Inconsistent
  means that there is both ``CRLF`` and ``LF`` present in the file.
  Such files are normally not touched under the assumption that they
  have mixed EOLs on purpose.

- ``eol.fix-trailing-newline`` (default False) can be set to True to
  ensure that converted files end with a EOL character (either ``\\n``
  or ``\\r\\n`` as per the configured patterns).

The extension provides ``cleverencode:`` and ``cleverdecode:`` filters
like the deprecated win32text extension does. This means that you can
disable win32text and enable eol and your filters will still work. You
only need to these filters until you have prepared a ``.hgeol`` file.

The ``win32text.forbid*`` hooks provided by the win32text extension
have been unified into a single hook named ``eol.checkheadshook``. The
hook will lookup the expected line endings from the ``.hgeol`` file,
which means you must migrate to a ``.hgeol`` file first before using
the hook. ``eol.checkheadshook`` only checks heads, intermediate
invalid revisions will be pushed. To forbid them completely, use the
``eol.checkallhook`` hook. These hooks are best used as
``pretxnchangegroup`` hooks.

See :hg:`help patterns` for more information about the glob patterns
used.
"""

from __future__ import absolute_import

import os
import re

from edenscm.mercurial import (
    config,
    error as errormod,
    extensions,
    match,
    pycompat,
    registrar,
    util,
)
from edenscm.mercurial.i18n import _
from edenscm.mercurial.pycompat import range


# Note for extension authors: ONLY specify testedwith = 'ships-with-hg-core' for
# extensions which SHIP WITH MERCURIAL. Non-mainline extensions should
# be specifying the version(s) of Mercurial they are tested with, or
# leave the attribute unspecified.
testedwith = "ships-with-hg-core"

configtable = {}
configitem = registrar.configitem(configtable)

configitem("eol", "fix-trailing-newline", default=False)
configitem("eol", "native", default=pycompat.oslinesep)
configitem("eol", "only-consistent", default=True)

# Matches a lone LF, i.e., one that is not part of CRLF.
singlelf = re.compile(b"(^|[^\r])\n")


def inconsistenteol(data):
    return b"\r\n" in data and singlelf.search(data)


def tolf(s, params, ui, **kwargs):
    """Filter to convert to LF EOLs."""
    if util.binary(s):
        return s
    if ui.configbool("eol", "only-consistent") and inconsistenteol(s):
        return s
    if ui.configbool("eol", "fix-trailing-newline") and s and s[-1:] != b"\n":
        s = s + b"\n"
    return pycompat.encodeutf8(util.tolf(pycompat.decodeutf8(s)))


def tocrlf(s, params, ui, **kwargs):
    """Filter to convert to CRLF EOLs."""
    if util.binary(s):
        return s
    if ui.configbool("eol", "only-consistent") and inconsistenteol(s):
        return s
    if ui.configbool("eol", "fix-trailing-newline") and s and s[-1:] != b"\n":
        s = s + b"\n"
    return pycompat.encodeutf8(util.tocrlf(pycompat.decodeutf8(s)))


def isbinary(s, params, *args, **kwargs):
    """Filter to do nothing with the file."""
    return s


filters = {
    "to-lf": tolf,
    "to-crlf": tocrlf,
    "is-binary": isbinary,
    # The following provide backwards compatibility with win32text
    "cleverencode:": tolf,
    "cleverdecode:": tocrlf,
}


class eolfile(object):
    def __init__(self, ui, root, data):
        self._decode = {"LF": "to-lf", "CRLF": "to-crlf", "BIN": "is-binary"}
        self._encode = {"LF": "to-lf", "CRLF": "to-crlf", "BIN": "is-binary"}

        self.cfg = config.config()
        # Our files should not be touched. The pattern must be
        # inserted first override a '** = native' pattern.
        self.cfg.set("patterns", ".hg*", "BIN", "eol")
        # We can then parse the user's patterns.
        self.cfg.parse(".hgeol", data)

        isrepolf = self.cfg.get("repository", "native") != "CRLF"
        self._encode["NATIVE"] = isrepolf and "to-lf" or "to-crlf"
        iswdlf = ui.config("eol", "native") in ("LF", "\n")
        self._decode["NATIVE"] = iswdlf and "to-lf" or "to-crlf"

        include = []
        exclude = []
        self.patterns = []
        for pattern, style in self.cfg.items("patterns"):
            key = style.upper()
            if key == "BIN":
                exclude.append(pattern)
            else:
                include.append(pattern)
            m = match.match(root, "", [pattern])
            self.patterns.append((pattern, key, m))
        # This will match the files for which we need to care
        # about inconsistent newlines.
        self.match = match.match(root, "", [], include, exclude)

    def copytoui(self, ui):
        for pattern, key, m in self.patterns:
            try:
                ui.setconfig("decode", pattern, self._decode[key], "eol")
                ui.setconfig("encode", pattern, self._encode[key], "eol")
            except KeyError:
                ui.warn(
                    _("ignoring unknown EOL style '%s' from %s\n")
                    % (key, self.cfg.source("patterns", pattern))
                )
        # eol.only-consistent can be specified in ~/.hgrc or .hgeol
        for k, v in self.cfg.items("eol"):
            ui.setconfig("eol", k, v, "eol")

    def checkrev(self, repo, ctx, files):
        failed = []
        for f in files or ctx.files():
            if f not in ctx:
                continue
            for pattern, key, m in self.patterns:
                if not m(f):
                    continue
                target = self._encode[key]
                data = ctx[f].data()
                if (
                    target == "to-lf"
                    and b"\r\n" in data
                    or target == "to-crlf"
                    and singlelf.search(data)
                ):
                    failed.append((f, target, str(ctx)))
                break
        return failed


def parseeol(ui, repo, nodes):
    try:
        for node in nodes:
            try:
                if node is None:
                    # Cannot use workingctx.data() since it would load
                    # and cache the filters before we configure them.
                    data = repo.wvfs(".hgeol").read()
                else:
                    data = repo[node][".hgeol"].data()
                data = pycompat.decodeutf8(data)
                return eolfile(ui, repo.root, data)
            except (IOError, LookupError):
                pass
    except errormod.ParseError as inst:
        ui.warn(
            _("warning: ignoring .hgeol file due to parse error " "at %s: %s\n")
            % (inst.args[1], inst.args[0])
        )
    return None


def ensureenabled(ui):
    """make sure the extension is enabled when used as hook

    When eol is used through hooks, the extension is never formally loaded and
    enabled. This has some side effect, for example the config declaration is
    never loaded. This function ensure the extension is enabled when running
    hooks.
    """
    if "eol" in ui.uiconfig()._knownconfig:
        return
    ui.setconfig("extensions", "eol", "", source="internal")
    extensions.loadall(ui, ["eol"])


def _checkhook(ui, repo, node, headsonly):
    # Get revisions to check and touched files at the same time
    ensureenabled(ui)
    files = set()
    revs = set()
    for rev in range(repo[node].rev(), len(repo)):
        revs.add(rev)
        if headsonly:
            ctx = repo[rev]
            files.update(ctx.files())
            for pctx in ctx.parents():
                revs.discard(pctx.rev())
    failed = []
    for rev in revs:
        ctx = repo[rev]
        eol = parseeol(ui, repo, [ctx.node()])
        if eol:
            failed.extend(eol.checkrev(repo, ctx, files))

    if failed:
        eols = {"to-lf": "CRLF", "to-crlf": "LF"}
        msgs = []
        for f, target, node in sorted(failed):
            msgs.append(
                _("  %s in %s should not have %s line endings")
                % (f, node, eols[target])
            )
        raise errormod.Abort(_("end-of-line check failed:\n") + "\n".join(msgs))


def checkallhook(ui, repo, node, hooktype, **kwargs):
    """verify that files have expected EOLs"""
    _checkhook(ui, repo, node, False)


def checkheadshook(ui, repo, node, hooktype, **kwargs):
    """verify that files have expected EOLs"""
    _checkhook(ui, repo, node, True)


# "checkheadshook" used to be called "hook"
hook = checkheadshook


def preupdate(ui, repo, hooktype, parent1, parent2):
    repo.loadeol([parent1])
    return False


def uisetup(ui):
    ui.setconfig("hooks", "preupdate.eol", preupdate, "eol")


def extsetup(ui):
    try:
        extensions.find("win32text")
        ui.warn(
            _("the eol extension is incompatible with the " "win32text extension\n")
        )
    except KeyError:
        pass


def reposetup(ui, repo):
    uisetup(repo.ui)

    if not repo.local():
        return
    for name, fn in pycompat.iteritems(filters):
        repo.adddatafilter(name, fn)

    ui.setconfig("patch", "eol", "auto", "eol")

    class eolrepo(repo.__class__):
        def loadeol(self, nodes):
            eol = parseeol(self.ui, self, nodes)
            if eol is None:
                return None
            eol.copytoui(self.ui)
            return eol.match

        def _hgcleardirstate(self):
            self._eolmatch = self.loadeol([None, "tip"])
            if not self._eolmatch:
                self._eolmatch = util.never
                return

            oldeol = None
            try:
                cachemtime = os.path.getmtime(self.localvfs.join("eol.cache"))
            except OSError:
                cachemtime = 0
            else:
                olddata = self.localvfs.read("eol.cache")
                if olddata:
                    olddata = pycompat.decodeutf8(olddata)
                    oldeol = eolfile(self.ui, self.root, olddata)

            try:
                eolmtime = os.path.getmtime(self.wjoin(".hgeol"))
            except OSError:
                eolmtime = 0

            if eolmtime > cachemtime:
                self.ui.debug("eol: detected change in .hgeol\n")

                hgeoldata = self.wvfs.read(".hgeol")
                hgeoldata = pycompat.decodeutf8(hgeoldata)
                neweol = eolfile(self.ui, self.root, hgeoldata)

                try:
                    with repo.wlock(), repo.lock(), repo.transaction("eol"):
                        for f in self.dirstate:
                            if self.dirstate[f] != "n":
                                continue
                            if oldeol is not None:
                                if not oldeol.match(f) and not neweol.match(f):
                                    continue
                                oldkey = None
                                for pattern, key, m in oldeol.patterns:
                                    if m(f):
                                        oldkey = key
                                        break
                                newkey = None
                                for pattern, key, m in neweol.patterns:
                                    if m(f):
                                        newkey = key
                                        break
                                if oldkey == newkey:
                                    continue
                            # all normal files need to be looked at again since
                            # the new .hgeol file specify a different filter
                            self.dirstate.normallookup(f)
                        # Write the cache to update mtime and cache .hgeol
                        with self.localvfs("eol.cache", "wb") as f:
                            f.write(pycompat.encodeutf8(hgeoldata))
                except errormod.LockUnavailable:
                    # If we cannot lock the repository and clear the
                    # dirstate, then a commit might not see all files
                    # as modified. But if we cannot lock the
                    # repository, then we can also not make a commit,
                    # so ignore the error.
                    pass

        def commitctx(self, ctx, error=False):
            for f in sorted(ctx.added() + ctx.modified()):
                if not self._eolmatch(f):
                    continue
                fctx = ctx[f]
                if fctx is None:
                    continue
                data = fctx.data()
                if util.binary(data):
                    # We should not abort here, since the user should
                    # be able to say "** = native" to automatically
                    # have all non-binary files taken care of.
                    continue
                if inconsistenteol(data):
                    raise errormod.Abort(_("inconsistent newline style " "in %s\n") % f)
            return super(eolrepo, self).commitctx(ctx, error)

    repo.__class__ = eolrepo
    repo._hgcleardirstate()
