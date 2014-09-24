-------------------------------------------------------------------
-- |
-- Module       : Data.Binomial
-- Copyright    : (C) 2014
-- License      : BSD-style (see the file etc/LICENSE.md)
-- Maintainer   : Dom De Re
--
-- From Chapter 3 of Purely Functional Data Structures,
-- Binomial Trees are defined inductively as:
--      *   A singleton node has rank 0
--      *   A binomial tree of rank r + 1 is formed by linking 2
--          binomial trees of rank r, having one tree as the
--          child of the other
--
-- A binomial tree or rank r can also be defined as a node
-- containing an element and r children trees t1, t2,..,ti,..,tr
-- where each ti has rank r - i. Hence the definition of BinomialTree,
-- Note that the children are to be stored in order of decreasing rank and
-- elements are to be stored in heap order.
--
-------------------------------------------------------------------
module Data.Binomial where

import LocalPrelude

import Data.Bool ( (&&) )

data BinomialTreeList a =
        Nil
    |   Cons (BinomialTreeList a) (BinomialTree a)
        deriving (Show, Eq)

{-@

    measure listlen :: BinomialTreeList a -> Int
    listlen (Nil)       = 0
    listlen (Cons xs x) = 1 + (listlen xs)

@-}

{-@ type BinomialTreeListN a N = {t : BinomialTreeList a | (listlen t) = N } @-}

{-@

    data BinomialTreeList a =
            Nil
        |   Cons (ts :: BinomialTreeList a) (t :: BinomialTreeN a {(listlen ts)})

@-}

data BinomialTree a = BinomialTree Int a (BinomialTreeList a) deriving (Show, Eq)

{-@

    measure binTreeRank :: BinomialTree a -> Int
    binTreeRank (BinomialTree r x cs) = r

@-}

{-@ type BinomialTreeN a N = {t : BinomialTree a | (binTreeRank t) = N} @-}
{-@ type ListN a N = {xs : [a] | (len xs) = N} @-}

{-@

    data BinomialTree [binTreeRank] a =
        BinomialTree (r :: Int) (x :: a) (cs :: BinomialTreeListN a {r})

@-}

{-@ rank :: v : BinomialTree a -> {x : Int | x = (binTreeRank v)} @-}
rank :: BinomialTree a -> Int
rank (BinomialTree r _ _) = r
-- rank (BinomialTree _ _ cs) = length cs
-- rank _ = 0

{-@ singletonTree :: a -> BinomialTreeN a {0} @-}
singletonTree :: a -> BinomialTree a
singletonTree x = BinomialTree 0 x Nil

-- |
-- the decreasing rank invariant isnt enforced
-- you still have to rely on building it up from `singletonTree` and `link`
-- hence this doesnt get flagged as unsafe.
--
{-% badTree :: a -> BinomialTreeN a {1} %-}
--badTree x = BinomialTree 2 x (Cons (Cons Nil (singletonTree x)) (singletonTree x))

{-@ goodTree :: (Ord a) => a -> BinomialTreeN a {1} @-}
goodTree :: (Ord a) => a -> BinomialTree a
goodTree x = link (singletonTree x) (singletonTree x)

{-@ link :: (Ord a) => w : BinomialTree a -> z : BinomialTreeN a {(binTreeRank w)} -> BinomialTreeN a {1 + (binTreeRank w)} @-}
link :: (Ord a) => BinomialTree a -> BinomialTree a -> BinomialTree a
link w@(BinomialTree rw x ws) z@(BinomialTree rz y zs)
    | x < y     = BinomialTree (rw + 1) x (Cons ws z)
    | otherwise = BinomialTree (rz + 1) y (Cons zs w)

-- helpers

isStrictlyDecreasing :: (Ord b) => (a -> b) -> [a] -> Bool
isStrictlyDecreasing _ [] = True
isStrictlyDecreasing _ (_:[]) = True
isStrictlyDecreasing f (x : y : xs) = (f x > f y) && isStrictlyDecreasing f (y : xs)
