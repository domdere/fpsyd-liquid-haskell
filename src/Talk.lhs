% Refined Types
% Dom De Re (fp-syd)
% 24 Sept, 2014

Partiality
==========

Module Header

>   module Talk where
>   import Prelude ( undefined )

-----------

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

-----------------

Partial functions are convenient to write, inconvenient to trust.

Total functions give complete coverage of the domains they promise to cover.

The Rabbit Hole
===============

Adulterate the output
---------------------

``` Haskell
head' :: [a] -> Maybe a
head' (x : _)   = Just x
head' []        = Nothing

tail' :: [a] -> Maybe [a]
tail' (_ : xs)  = Just xs
tail' []        = Nothing
```

------------------

When we qualify our types we tend to adulterate them

------------------

``` Haskell
data Maybe a =
        Nothing
    |   Just a
```

-----------------

``` Haskell
data Either a b =
        Left a
    |   Right b
```

-----------------

``` Haskell
data [] a =
        []
    |   a : [a]
```

----------------

``` Haskell
data State s a = State { runState :: s -> (a, s) }
```

An exception
------------

``` Haskell
data Const r a = Const { runConst :: r }
```

-----------

Abstractions to help us manage these types:

``` Haskell
class Applicative f where
    pure :: a -> f a
    (<*>) :: f (a -> b) -> f a -> f b

class Monad m where
    return :: a -> m a
    (>>=) :: m a -> (a -> m b) -> m b
```

Red Black Trees
===============

Tree
---------------

``` Haskell
data Tree a =
        Leaf
    |   Node a (Tree a) (Tree a)
```

Red Black Tree
--------------

``` Haskell
data Colour =
        Red
    |   Black

data RedBlack a =
        Leaf
    |   Node Colour a (RedBlack a) (RedBlack a)
```

-------------

Erm, just be careful about breaking the invariants!

1.  Red nodes can't have red children (leaf nodes are considered to be black).
2.  All paths from the root to the leaf nodes must have the same number of black nodes

There's a whole bunch of values of type `RedBlack a` that will never come up but must still
be handled in our functions.

-------------

Let's refine for Invariant 1:

``` Haskell
data BlackNode a =
        Leaf
    |   BlackNode a (RedBlack a) (RedBlack a)

data RedNode a = RedNode a (BlackNode a) (BlackNode a)

data RedBlack a = R (RedNode a) | B (BlackNode a)
```

Non-surjectivity
============

-----------

The image of a surjective function is equal to its codomain.

The particular case of interest though is just unused patterns in the output type.

This sometimes means that functions called further down the chain are forced to deal with patterns that wouldn't
logically be possible, maybe partial functions.

-----------

``` Haskell
data Error = InsertError | UpdateError

insert :: (MonadIO m) => a -> EitherT Error m a
insert x = do
    insertRest <- realInsert x
    return $ maybe (left InsertError) pure insertRest

insertErrorHandler :: (MonadIO m) => Error -> m a
insertErrorHandler (InsertError) = someContextuallyValidResponse
insertErrorHandler (UpdateError) = somethingJustNeedsToBeHere
```


Pandoc
======

You will need Pandoc
--------------------

[**Pandoc**] [pandoc] gets the Literate Haskell source file (or Markdown file) and marks it up into slides.

Installing **Pandoc**
---------------------

-   On **Ubuntu**, you can install it with the package manager: `sudo apt-get install pandoc`
-   However if you are rendering a Literate Haskell file, you are likely to be familiar with `cabal` and `ghc`, in which case you can install it like you would any other Haskell binary off Hackage.

LaTeX and Beamer
================

Installing LaTeX and Beamer
---------------------------

If you wish to build the `beamer` target, you will need to install the `latex-beamer` package with:

```
sudo apt-get install latex-beamer
```

Write Slides
============

-----------

You can write your slides in [**Github flavoured Markdown**] [github-markdown] mixed with or without [**Literate Haskell**] [lhs]

Github Flavoured Markdown Example
---------------------------------

A Python excerpt:

``` Python
def erp(r, x):
    print("erpderp")
```

Literate Haskell 1 (Bird Style)
------------------------------

Ordinarily in Markdown, a `>` character at the beginning of a line would signify a quote block.

When using Literate Haskell however, a `>` at the beginning of a line will signify a line of **Haskell** code that you want both marked up in the slides and compiled into the module

> foldr' :: (a -> b -> b) -> b -> [a] -> b
> foldr' _ y []     = y
> foldr' f y (x:xs) = f x (foldr' f y xs)

Literate Haskell 2
------------------

If you want to write broken code without it stopping the module from compiling, there are two ways to do it.

You can start the line with a `<` char instead of a `>` char:

< -- | This wouldn't compile
< foo :: a -> b
< foo x = x

Or you can embed `Haskell` code the way you already would in Github Flavoured Markdown:

``` Haskell
-- | This would not compile either
foo2 :: (s -> a) -> (s -> b -> t) -> (a -> b) -> s -> t
foo2 g s w x = g s
```

Building The Slides
===================

---------

`pandoc` can output a wide variety of formats, right now, the included `Makefile` only builds a small subset of them

Reveal.js
---------

Build the slides with:

```
make revealjs
```

By default it uses the `sky` theme and sets the `slide-level` to 2

Output goes to `revealjs/index.html`

Beamer
------

Build the slides with:

```
make beamer
```

It uses the default theme and also sets the `slide-level` to 2

Output goes to `beamer/talk.pdf`

[pandoc]: http://johnmacfarlane.net/pandoc/ "Pandoc"
[github-markdown]: https://help.github.com/articles/github-flavored-markdown "Github flavoured Markdown"
[lhs]: http://www.haskell.org/haskellwiki/Literate_programming
