# Portions Copyright (c) Facebook, Inc. and its affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

# changelog.py - changelog class for mercurial
#
# Copyright 2005-2007 Matt Mackall <mpm@selenic.com>
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2 or any later version.

from __future__ import absolute_import

from typing import IO, Any, Dict, List, Optional, Union

import bindings

from . import encoding, error, mdiff, revlog, util, visibility
from .i18n import _
from .node import bbin, bin, hex, nullid, nullrev, wdirid, wdirrev
from .pycompat import decodeutf8, encodeutf8, iteritems, range, isint
from .thirdparty import attr


_defaultextra = {"branch": "default"}

textwithheader = revlog.textwithheader


def _string_escape(text):
    """
    >>> from .pycompat import bytechr as chr
    >>> d = {b'nl': chr(10), b'bs': chr(92), b'cr': chr(13), b'nul': chr(0)}
    >>> s = b"ab%(nl)scd%(bs)s%(bs)sn%(nul)sab%(cr)scd%(bs)s%(nl)s" % d
    >>> s
    'ab\\ncd\\\\\\\\n\\x00ab\\rcd\\\\\\n'
    >>> res = _string_escape(s)
    >>> s == util.unescapestr(res)
    True
    """
    # subset of the string_escape codec
    text = text.replace("\\", "\\\\").replace("\n", "\\n").replace("\r", "\\r")
    return text.replace("\0", "\\0")


def decodeextra(text):
    # type: (bytes) -> Dict[str, str]
    """
    >>> from .pycompat import bytechr as chr
    >>> sorted(decodeextra(encodeextra({b'foo': b'bar', b'baz': chr(0) + b'2'})
    ...                    ).items())
    [('baz', '\\x002'), ('branch', 'default'), ('foo', 'bar')]
    >>> sorted(decodeextra(encodeextra({b'foo': b'bar',
    ...                                 b'baz': chr(92) + chr(0) + b'2'})
    ...                    ).items())
    [('baz', '\\\\\\x002'), ('branch', 'default'), ('foo', 'bar')]
    """
    extra = _defaultextra.copy()
    for l in text.split(b"\0"):
        if l:
            if b"\\0" in l:
                # fix up \0 without getting into trouble with \\0
                l = l.replace(b"\\\\", b"\\\\\n")
                l = l.replace(b"\\0", b"\0")
                l = l.replace(b"\n", b"")
            k, v = util.unescapestr(l).split(":", 1)
            extra[k] = v
    return extra


def encodeextra(d):
    for k, v in iteritems(d):
        if not isinstance(v, str):
            raise ValueError("extra '%s' should be type str not %s" % (k, v.__class__))

    # keys must be sorted to produce a deterministic changelog entry
    items = [_string_escape("%s:%s" % (k, d[k])) for k in sorted(d)]
    return "\0".join(items)


def stripdesc(desc):
    """strip trailing whitespace and leading and trailing empty lines"""
    return "\n".join([l.rstrip() for l in desc.splitlines()]).strip("\n")


@attr.s
class _changelogrevision(object):
    # Extensions might modify _defaultextra, so let the constructor below pass
    # it in
    extra = attr.ib()
    manifest = attr.ib(default=nullid)
    user = attr.ib(default="")
    date = attr.ib(default=(0, 0))
    files = attr.ib(default=attr.Factory(list))
    description = attr.ib(default="")


class changelogrevision(object):
    """Holds results of a parsed changelog revision.

    Changelog revisions consist of multiple pieces of data, including
    the manifest node, user, and date. This object exposes a view into
    the parsed object.
    """

    __slots__ = (u"_offsets", u"_text", u"_files")

    def __new__(cls, text):
        if not text:
            return _changelogrevision(extra=_defaultextra)

        self = super(changelogrevision, cls).__new__(cls)
        # We could return here and implement the following as an __init__.
        # But doing it here is equivalent and saves an extra function call.

        # format used:
        # nodeid\n        : manifest node in ascii
        # user\n          : user, no \n or \r allowed
        # time tz extra\n : date (time is int or float, timezone is int)
        #                 : extra is metadata, encoded and separated by '\0'
        #                 : older versions ignore it
        # files\n\n       : files modified by the cset, no \n or \r allowed
        # (.*)            : comment (free text, ideally utf-8)
        #
        # changelog v0 doesn't use extra

        nl1 = text.index(b"\n")
        nl2 = text.index(b"\n", nl1 + 1)
        nl3 = text.index(b"\n", nl2 + 1)

        # The list of files may be empty. Which means nl3 is the first of the
        # double newline that precedes the description.
        if text[nl3 + 1 : nl3 + 2] == b"\n":
            doublenl = nl3
        else:
            doublenl = text.index(b"\n\n", nl3 + 1)

        self._offsets = (nl1, nl2, nl3, doublenl)
        self._text = text
        self._files = None

        return self

    @property
    def manifest(self):
        return bbin(self._text[0 : self._offsets[0]])

    @property
    def user(self):
        off = self._offsets
        return encoding.tolocalstr(self._text[off[0] + 1 : off[1]])

    @property
    def _rawdate(self):
        off = self._offsets
        dateextra = self._text[off[1] + 1 : off[2]]
        return dateextra.split(b" ", 2)[0:2]

    @property
    def _rawextra(self):
        off = self._offsets
        dateextra = self._text[off[1] + 1 : off[2]]
        fields = dateextra.split(b" ", 2)
        if len(fields) != 3:
            return None

        return fields[2]

    @property
    def date(self):
        raw = self._rawdate
        time = float(raw[0])
        # Various tools did silly things with the timezone.
        try:
            timezone = int(raw[1])
        except ValueError:
            timezone = 0

        return time, timezone

    @property
    def extra(self):
        raw = self._rawextra
        if raw is None:
            return _defaultextra

        return decodeextra(raw)

    @property
    def files(self):
        if self._files is not None:
            return self._files

        off = self._offsets
        if off[2] == off[3]:
            self._files = tuple()
        else:
            self._files = tuple(decodeutf8(self._text[off[2] + 1 : off[3]]).split("\n"))
        return self._files

    @property
    def description(self):
        return encoding.tolocalstr(self._text[self._offsets[3] + 2 :])


def readfiles(text):
    # type: (bytes) -> List[str]
    """
    >>> from .pycompat import bytechr as chr
    >>> d = {'nl': chr(10)}
    >>> withfiles = b'commitnode%(nl)sAuthor%(nl)sMetadata and extras%(nl)sfile1%(nl)sfile2%(nl)sfile3%(nl)s%(nl)s' % d
    >>> readfiles(withfiles)
    ['file1', 'file2', 'file3']
    >>> withoutfiles = b'commitnode%(nl)sAuthor%(nl)sMetadata and extras%(nl)s%(nl)sCommit summary%(nl)s%(nl)sCommit description%(nl)s' % d
    >>> readfiles(withoutfiles)
    []
    """
    if not text:
        return []

    first = 0
    last = text.index(b"\n\n")

    n = 3
    while n != 0:
        try:
            first = text.index(b"\n", first, last) + 1
        except ValueError:
            return []
        n -= 1

    return decodeutf8(text[first:last]).split("\n")


def hgcommittext(manifest, files, desc, user, date, extra):
    """Generate the 'text' of a commit"""
    # Convert to UTF-8 encoded bytestrings as the very first
    # thing: calling any method on a localstr object will turn it
    # into a str object and the cached UTF-8 string is thus lost.
    user, desc = encoding.fromlocal(user), encoding.fromlocal(desc)

    user = user.strip()
    # An empty username or a username with a "\n" will make the
    # revision text contain two "\n\n" sequences -> corrupt
    # repository since read cannot unpack the revision.
    if not user:
        raise error.RevlogError(_("empty username"))
    if "\n" in user:
        raise error.RevlogError(_("username %s contains a newline") % repr(user))

    desc = stripdesc(desc)

    if date:
        parseddate = "%d %d" % util.parsedate(date)
    else:
        parseddate = "%d %d" % util.makedate()
    if extra:
        branch = extra.get("branch")
        if branch in ("default", ""):
            del extra["branch"]
        elif branch in (".", "null", "tip"):
            raise error.RevlogError(_("the name '%s' is reserved") % branch)
    if extra:
        extra = encodeextra(extra)
        parseddate = "%s %s" % (parseddate, extra)
    l = [hex(manifest), user, parseddate] + sorted(files) + ["", desc]
    text = encodeutf8("\n".join(l), errors="surrogateescape")
    return text
