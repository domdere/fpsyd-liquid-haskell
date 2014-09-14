-------------------------------------------------------------------
-- |
-- Module       : Data.OrdList
-- Copyright    : (C) 2014
-- License      : BSD-style (see the file etc/LICENSE.md)
-- Maintainer   : Dom De Re
--
-- A look at Statically verifying the invariants of GHC's OrdList type
-- (<http://www.haskell.org/platform/doc/2013.2.0.0/ghc-api/OrdList.html>)
--
-------------------------------------------------------------------
module Data.OrdList (
    -- * Type
        OrdList
    ) where

import LocalPrelude

import Data.Functor ( fmap )
import Data.List ( map )
import Data.List.NonEmpty ( NonEmpty(..), nonEmpty )
import Data.Maybe ( maybe )

data OrdList a =
        Empty
    |   One a
    |   Many (NonEmpty a)
    |   Cons a (OrdList a)
    |   Snoc (OrdList a) a
    |   Two (OrdList a) (OrdList a) -- ^ The Invariant that must be maintained is that these two ordlists must be non-empty..

{-@
    measure nelen :: NonEmpty a -> Int
    nelen ((:|) x xs) = 1 + (len xs)
@-}

{-@
    measure olen :: OrdList a -> Int
    olen (Empty)        = 0
    olen (One x)        = 1
    olen (Many xs)      = (nelen xs)
    olen (Cons x xs)    = 1 + (olen xs)
    olen (Snoc xs x)    = 1 + (olen xs)
    olen (Two xs ys)    = (olen xs) + (olen ys)
@-}

{-@ invariant {v : OrdList a | (olen v) >= 0 } @-}

{-@ type NEOrdList a = {v : OrdList a | (olen v) >= 0} @-}

{-@

    data OrdList [olen] a =
            Empty
        |   One (x :: a)
        |   Many (xs :: NonEmpty a)
        |   Cons (x :: a) (xs :: OrdList a)
        |   Snoc (xs :: OrdList a) (x :: a)
        |   Two (xs :: NEOrdList a) (ys :: NEOrdList a)

@-}

{-@ type OrdListN a N = {v : OrdList a | (olen v) = N} @-}

{-@ emptyOrdList :: OrdListN a {0} @-}
emptyOrdList :: OrdList a
emptyOrdList = Empty

{-@ singletonOrdList :: a -> OrdListN a {1} @-}
singletonOrdList :: a -> OrdList a
singletonOrdList = One

{-@ consOL :: a -> xs : OrdList a -> OrdListN a {1 + (olen xs)} @-}
consOL :: a -> OrdList a -> OrdList a
consOL = Cons

{-@ appendOL :: xs : OrdList a -> ys : OrdList a -> OrdListN a {(olen xs) + (olen ys)} @-}
appendOL :: OrdList a -> OrdList a -> OrdList a
appendOL Empty xs = xs
appendOL xs Empty = xs
appendOL (One x) xs = Cons x xs
appendOL xs (One x) = Snoc xs x
appendOL xs ys = Two xs ys

{-@ fromList :: xs : [a] -> OrdListN a {(len xs)} @-}
fromList :: [a] -> OrdList a
fromList [] = Empty
fromList (x:xs) = Many (x :| xs)
--fromList = maybe Empty Many . nonEmpty

{-@ mapNE :: (a -> b) -> xs : NonEmpty a -> {ys : NonEmpty b | (nelen ys) = (nelen xs)} @-}
mapNE :: (a -> b) -> NonEmpty a -> NonEmpty b
mapNE f (x :| xs) = (f x) :| (map f xs)

{-@ mapOL :: (a -> b) -> xs : OrdList a -> OrdListN b {(olen xs)} @-}
mapOL :: (a -> b) -> OrdList a -> OrdList b
mapOL _ Empty       = Empty
mapOL f (One x)     = One (f x)
mapOL f (Many xs)   = (Many . mapNE f) xs
mapOL f (Cons x xs) = Cons (f x) (mapOL f xs)
mapOL f (Snoc xs x) = Snoc (mapOL f xs) (f x)
mapOL f (Two xs ys) = Two (mapOL f xs) (mapOL f ys)
