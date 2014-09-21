-------------------------------------------------------------------
-- |
-- Module       : Data.RedBlack
-- Copyright    : (C) 2014
-- License      : BSD-style (see the file etc/LICENSE.md)
-- Maintainer   : Dom De Re
--
-- RedBlack Trees
--
-------------------------------------------------------------------
module Data.RedBlack (
    -- * Types
        Colour(..)
    ,   RedBlack
    ) where

import LocalPrelude

data Colour = Red | Black deriving (Show, Eq)

data BlackNode a =
        Leaf
    |   BlackNode a (RedBlack a) (RedBlack a)
        deriving (Show, Eq)

{-%
    measure bdepth :: BlackNode a -> Int
    bdepth (Leaf) = 1
    bdepth (BlackNode x l r) = 1 + (rbdepth l)
%-}

{-% type BlackNodeN a N = {t : BlackNode a | (bdepth t) = N} %-}

{-%

    data BlackNode [bdepth] a =
            Leaf
        |   BlackNode (x :: a) (l :: RedBlack a) (r :: RedBlackN a {(rbdepth l)})

%-}

data RedNode a = RedNode a (BlackNode a) (BlackNode a) deriving (Show, Eq)

{-%

    measure rdepth :: RedNode a -> Int
    rdepth (RedNode x l r) = (bdepth l)

%-}

{-% type RedNodeN a N = {t : RedNode a | (rdepth t) = N} %-}

{-%

    data RedNode [rdepth] a =
        RedNode (x :: a) (l :: BlackNode a) (r :: BlackNodeN a {(bdepth l)})

%-}

-- |
-- A Red Black Tree, 2 invariants:
--
-- 1) No Red node has a Red child
-- 2) Every Path from the root to an empty node has the same number of Black nodes
--
data RedBlack a =
        R (RedNode a)
    |   B (BlackNode a)
        deriving (Show, Eq)

{-%
    measure colourlen :: Colour -> Int
    colourlen (Red)     = 0
    colourlen (Black)   = 1
%-}

{-%
    measure treeColour :: RedBlack a -> Colour
    treeColour (Leaf)   = Black
    treeColour (R x)    = Red
    treeColour (B x)    = Black
%-}

{-%
    measure rbdepth :: RedBlack a -> Int
    rbdepth (R x)   = (rdepth x)
    rbdepth (B x)   = (bdepth x)
%-}

{-% type RedBlackN a N = {t : RedBlack a | (rbdepth t) = N} %-}
{-% type BlackRoot a = {t : RedBlack a | (treeColour t) = Black} %-}
{-% type BlackRootN a N = {t : BlackRoot a | (rbdepth t) = N} %-}

-- |
-- While we are inserting an element, the tree can be in an intermediate state
-- where one of the invariants is broken, a Red node can have a red child
--
data RedBlackBrokenAtRoot a =
        Ok (RedBlack a)
    |   BrokenRedNodeLeft a (RedNode a) (BlackNode a) -- ^ A Red Node with a left Red Child
    |   BrokenRedNodeRight a (BlackNode a) (RedNode a) -- ^ A Red Node with a right Red Child
        deriving (Show, Eq)

{-%

    measure brbdepth :: RedBlackBrokenAtRoot a -> Int
    brbdepth (Ok x)                     = (rbdepth x)
    brbdepth (BrokenRedNodeLeft x l r)  = (rdepth l)
    brbdepth (BrokenRedNodeRight x l r) = (bdepth l)

%-}

{-% type RedBlackBrokenAtRootN a N = {t : RedBlackBrokenAtRoot a | (brbdepth t) = N} %-}

{-%

data RedBlackBrokenAtRoot a =
        Ok (t :: RedBlack a)
    |   BrokenRedNodeLeft (x :: a) (l :: RedNode a) (r :: BlackNodeN a {(rdepth l)})
    |   BrokenRedNodeRight (x :: a) (l :: BlackNode a) (r :: RedNodeN a {(bdepth l)})

%-}

colour :: RedBlack a -> Colour
colour (R _)    = Red
colour (B _)    = Black

{-% emptyRedBlack :: BlackRootN a {1} %-}
emptyRedBlack :: RedBlack a
emptyRedBlack = B Leaf

{-% singletonTree :: a -> BlackRootN a {2} %-}
singletonTree :: a -> RedBlack a
singletonTree x = B $ BlackNode x (B Leaf) (B Leaf)

{-% balanceblackl :: a -> l : RedBlackBrokenAtRoot a -> r : RedBlackN a {(brbdepth l)} -> RedBlackN a {(brbdepth l)} %-}
balanceblackl :: a -> RedBlackBrokenAtRoot a -> RedBlack a -> RedBlack a
balanceblackl z (BrokenRedNodeLeft y (RedNode x a b) c) d  = R $ RedNode y (BlackNode x (B a) (B b)) (BlackNode z (B c) d)
balanceblackl z (BrokenRedNodeRight x a (RedNode y b c)) d = R $ RedNode y (BlackNode x (B a) (B b)) (BlackNode z (B c) d)
balanceblackl x (Ok l) r                                   = B $ BlackNode x l r

{-% balanceblackr :: a -> l : RedBlack a -> r : RedBlackBrokenAtRootN a {(rbdepth l)} -> RedBlackN a {(rbdepth l)} %-}
balanceblackr :: a -> RedBlack a -> RedBlackBrokenAtRoot a -> RedBlack a
balanceblackr x a (BrokenRedNodeLeft z (RedNode y b c) d)  = R $ RedNode y (BlackNode x a (B b)) (BlackNode z (B c) (B d))
balanceblackr x a (BrokenRedNodeRight y b (RedNode z c d)) = R $ RedNode y (BlackNode x a (B b)) (BlackNode z (B c) (B d))
balanceblackr x l (Ok r)                                   = B $ BlackNode x l r

--balanceredl :: a -> RedBlackBrokenAtRoot a -> BlackNode a -> RedBlackBrokenAtRoot a
--balanceredl x a 

{-% toBroken :: v : RedBlack a -> RedBlackBrokenAtRootN a {(rbdepth v)} %-}
toBroken :: RedBlack a -> RedBlackBrokenAtRoot a
toBroken = Ok

{-% fixBroken :: v : RedBlackBrokenAtRoot a -> RedBlackN a {(brbdepth v)} %-}
fixBroken :: RedBlackBrokenAtRoot a -> RedBlack a
fixBroken (Ok x)                        = x
fixBroken (BrokenRedNodeLeft x l r)     = B $ BlackNode x (R l) (B r)
fixBroken (BrokenRedNodeRight x l r)    = B $ BlackNode x (B l) (R r)

{-% ins :: (Ord a) => a -> v : RedBlack a -> RedBlackBrokenAtRootN a {(rbdepth v)} %-}
ins :: (Ord a) => a -> RedBlack a -> RedBlackBrokenAtRoot a
ins x (B t) = Ok $ insBlack x t
ins x (R t) = insRed x t

{-% insBlack :: (Ord a) => a -> v : BlackNode a -> RedBlack a {(bdepth v)} %-}
insBlack :: (Ord a) => a -> BlackNode a -> RedBlack a
insBlack x Leaf = R $ RedNode x Leaf Leaf
insBlack x (BlackNode y l r)
    | x < y     = balanceblackl y (ins x l) r
    | otherwise = balanceblackr y l (ins x r)

{-% insRed :: (Ord a) => a -> v : RedNode a -> RedBlackBrokenAtRootN a {(rdepth v)} %-}
insRed :: (Ord a) => a -> RedNode a -> RedBlackBrokenAtRoot a
insRed x (RedNode y l r)
    |   x < y       = joinRedl y (insBlack x l) r
    |   otherwise   = joinRedr y l (insBlack x l)

{-% joinRedl :: a -> l : RedBlack a -> r : BlackNodeN a {(rbdepth l)} -> RedBlackBrokenAtRootN a {(rbdepth l)} %-}
joinRedl :: a -> RedBlack a -> BlackNode a -> RedBlackBrokenAtRoot a
joinRedl x (R l) r = BrokenRedNodeLeft x l r
joinRedl x (B l) r = Ok $ R $ RedNode x l r

{-% joinRedr :: a -> l : BlackNode a -> r : RedBlack a {(bdepth l)} -> RedBlackBrokenAtRootN a {(bdepth l)} %-}
joinRedr :: a -> BlackNode a -> RedBlack a -> RedBlackBrokenAtRoot a
joinRedr x l (R r) = BrokenRedNodeRight x l r
joinRedr x l (B r) = Ok $ R $ RedNode x l r

insert :: (Ord a) => a -> RedBlack a -> RedBlack a
insert x = fixBroken . ins x
