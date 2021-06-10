// @generated SignedSource<<eebfe270ef9871e8e9dcdee6d7a441cc>>
// DO NOT EDIT THIS FILE MANUALLY!
// This file is a mechanical copy of the version in the configerator repo. To
// modify it, edit the copy in the configerator repo instead and copy it over by
// running the following in your fbcode directory:
//
// configerator-thrift-updater scm/mononoke/redaction/redaction_set.thrift

struct RedactionSet {
  // SEV or task with more information on why this was redacted
  1: string reason;
  // Key to the redaction set in the blobstore
  2: string key;
  // If false, don't actually redact keys, only log when they are accessed
  3: bool enforce = true;
}

struct RedactionSets {
  // List of all redaction sets
  1: list<RedactionSet> all_redactions;
}