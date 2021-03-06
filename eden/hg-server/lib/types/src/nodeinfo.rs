/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2.
 */

use serde_derive::{Deserialize, Serialize};

use crate::{hgid::HgId, key::Key};

#[derive(
    Clone,
    Debug,
    Default,
    Eq,
    Hash,
    Ord,
    PartialEq,
    PartialOrd,
    Serialize,
    Deserialize
)]
pub struct NodeInfo {
    pub parents: [Key; 2],
    pub linknode: HgId,
}

#[cfg(any(test, feature = "for-tests"))]
use quickcheck::Arbitrary;

#[cfg(any(test, feature = "for-tests"))]
impl Arbitrary for NodeInfo {
    fn arbitrary(g: &mut quickcheck::Gen) -> Self {
        NodeInfo {
            parents: [Key::arbitrary(g), Key::arbitrary(g)],
            linknode: HgId::arbitrary(g),
        }
    }
}
