/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This software may be used and distributed according to the terms of the
 * GNU General Public License version 2.
 */

pub(crate) mod support {
    pub(crate) use crate::wire::{ToApi, ToWire};
    pub(crate) use insta_ext;
    pub(crate) use paste::paste;
    pub(crate) use quickcheck::{quickcheck, Arbitrary, Gen};

    pub(crate) fn check_wire_roundtrip<T>(original: T) -> bool
    where
        T: ToWire + Clone + PartialEq,
        <<T as ToWire>::Wire as ToApi>::Error: std::fmt::Debug,
    {
        let wire = original.clone().to_wire();
        let roundtrip = wire.to_api().unwrap();
        original == roundtrip
    }
}

macro_rules! auto_wire_tests {
    ($wire: ident $(,)?) => {
        $crate::wire::tests::support::paste!{
            #[test]
            fn [<auto_test_ $wire:snake>]() {
                use $crate::wire::tests::support::*;
                let mut g = Gen::from_seed(42);
                g.set_size(5);
                insta_ext::assert_json!($wire::arbitrary(&mut g));

                type Api = <$wire as ToApi>::Api;
                println!("Checking wire roundtrip");
                quickcheck(check_wire_roundtrip::<Api> as fn(Api) -> bool);
            }
        }
    };
    ($first: ident, $($rest: ident),* $(,)?) => {
        auto_wire_tests!($first);
        auto_wire_tests!($($rest),*);
    }
}
pub(crate) use auto_wire_tests;