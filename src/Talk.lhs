% Refined Types
% Dom De Re (fp-syd)
% 24 Sept, 2014

Partiality
==========

Module Header

>   module Talk where
>   import LocalPrelude
>   import Prelude ( undefined )
>   import Control.Lens ( Prism, prism, over )
>   import Data.Either ( Either(..) )
>   import Data.List.NonEmpty ( NonEmpty(..), nonEmpty )
>   import Data.Maybe ( Maybe, maybe )

-----------

It starts off so innocently:

``` Haskell
head' :: [a] -> a
head' (x : _)   = x
head' []        = undefined

tail' :: [a] -> [a]
tail' (_ : xs)  = xs
tail' []        = undefined
```

Whats the problem?
------------------

"Just don't give it an empty list."
    - Some Pragmatic Programmer


The Rabbit Hole
===============

---------------------

First we learn about `Maybe`, adulterate the type to add a rug to sweep the unwanted kernel under.

``` Haskell
head' :: [a] -> Maybe a
head' (x : _)   = Just x
head' []        = Nothing

tail' :: [a] -> Maybe [a]
tail' (_ : xs)  = Just xs
tail' []        = Nothing
```

------------------

We have abstractions to propagate things like `Maybe` to the end of the control flow:

``` Haskell
class Functor f where
    fmap :: (a -> b) -> f a -> f b

class (Functor f) => Applicative f where
    pure :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b

liftA2
    :: (Applicative f)
    => (a -> b -> c)
    -> f a -> f b -> f c

class Monad m where
    return :: a -> m a
    (>>=) :: m a -> (a -> m b) -> m b
```

------------------

But this is just a case of an unwanted pattern, rather than adulterate the output type, we could *refine* the input type:

``` Haskell
data NonEmpty a = a :| [a]

nonEmpty :: [a] -> Maybe (NonEmpty a)
nonEmpty (x : xs)   = Just $ x :| xs
nonEmpty []         = Nothing

head' :: NonEmpty a -> a
head' (x :| _) = x

tail' :: NonEmpty a -> [a]
tail' (_ :| xs) = xs
```

Functor
-------

And using the same machinery we can lift these simpler total functions up to the more complicated types:

``` Haskell
headl :: [a] -> Maybe a
headl = fmap head' . nonEmpty

taill :: [a] -> Maybe [a]
taill = fmap tail' . nonEmpty
```

Applicative
-----------

``` Haskell
liftA2
    :: (Applicative f)
    => (a -> b -> c)
    -> f a -> f b -> f c
```

Monad
-----

``` Haskell
(=<<)
    :: (Monad m)
    => (a -> m b)
    -> m a -> m b
```

Lens & Traversals
-----------------

>   fromList :: [a] -> Either [b] (NonEmpty a)
>   fromList = maybe (Left []) Right . nonEmpty
>
>   toList :: NonEmpty a -> [a]
>   toList (x :| xs) = x : xs
>
>   _NonEmpty :: Prism [a] [b] (NonEmpty a) (NonEmpty b)
>   _NonEmpty = prism toList fromList
>
>   dropTail :: NonEmpty a -> NonEmpty a
>   dropTail (x :| _) = x :| []

<   -- Provided you are happy with the "do nothing" response
<   -- for values in the kernel of fromList
<   over _NonEmpty
<       :: (NonEmpty a -> NonEmpty b)
<       -> [a] -> [b]

So....
------

We have a **lot** of tools to lift functions on simpler types into functions on more complex types.

This all sounds great, so where does it go wrong?

Rock Bottom
===========

A Binary Tree
-------------

``` Haskell
data Tree a =
        Leaf
    |   Node a (Tree a) (Tree a)
```

Red-Black Tree
--------------

``` Haskell
data Colour = Red | Black

data RBTree a =
        Leaf
    |   Node Colour a (RBTree a) (RBTree a)
```

Oh Wait!
---------

Invariants:

1.  Red nodes have no Red Children
2.  All paths from the root node to the leaves have the same number of black nodes

Properties
----------

-   This is a common use for properties, write up your properties that check that the invariants are valid in the output.
-   Write up your `Arbitrary` instance for your type that produces values that satisfy the invariant.

----------

-   Sometimes, writing up code that generates the invariant satisfying values ends up being very similar to the code you are testing...
-   On top of that concern, you have to worry about the coverage of the invariant satisfying subset.

----------

``` Haskell
insert
    :: (Ord a)
    => a
    -> RBTree a
    -> RBTree a

balance
    :: Colour
    -> a
    -> RBTree a
    -> RBTree a
    -> RBTree a
```

Let's Refine
------------

``` Haskell
data Colour = Red | Black

data RBTree a =
        Leaf
    |   Node Colour a (RBTree a) (RBTree a)
```

Bam!
-------

``` Haskell
-- Ignoring Invariant 2 since we only looking at inserts

data RedNode a = RedNode a (BlackNode a) (BlackNode a)

-- technically, the root node is supposed to be black, so this would represent
-- a red black tree in its final state.
data BlackNode a =
        Leaf
    |   BlackNode a (RedBlack a) (RedBlack a)

data RedBlack a = R (RedNode a) | B (BlackNode a)
```

--------

Oh, and while we are inserting a value into the tree, the tree can be in an intermediate state where Invariant 1 is broken at the root:

``` Haskell

-- This is assumed to e representing a Red Node at the root
data Invariant1Broken a =
        LeftRedChild a (RedNode a) (BlackNode a)
    |   RightRedChild a (BlackNode a) (RedNode a)

data InsertState a =
        Ok (RedBlack a)
    |   Broken (Invariant1Broken a)
```

--------

Wooo! Alright, now lets go rewrite those two simple yet incredibly bug prone functions!

--------

Before
--------

``` Haskell
insert
    :: (Ord a)
    => a
    -> RBTree a
    -> RBTree a

balance
    :: Colour
    -> a
    -> RBTree a
    -> RBTree a
    -> RBTree a
```

After
--------

``` Haskell
balanceblackl :: a -> InsertState a -> RedBlack a -> RedBlack a

balanceblackr :: a -> RedBlack a -> InsertState a -> RedBlack a

fixBroken :: InsertState a -> BlackNode a

ins :: (Ord a) => a -> RedBlack a -> InsertState a

insBlack :: (Ord a) => a -> BlackNode a -> RedBlack a

insRed :: (Ord a) => a -> RedNode a -> InsertState a

joinRedl :: a -> RedBlack a -> BlackNode a -> InsertState a

joinRedr :: a -> BlackNode a -> RedBlack a -> InsertState a

insert :: (Ord a) => a -> BlackNode a -> BlackNode a
```

---------

When the compiler finally released me I had realised I hadn't eaten for 5 days.

But I **don't** have a problem.

---------

-   The Rabbit hole goes further with Invariant 2 and deletes, with `DataKinds` or `GADTs`.
-   The deletes involve leaving the tree in an intermediate state where invariant 2 is broken.

Not going there in this talk.

Reflection
==========

----------

So whats the problem here?

What's the difference between the `[a]` / `NonEmpty a` case?

----------

-   All of the types could be injected into `RBTree a` much like `NonEmpty a` can be injected into [a].

