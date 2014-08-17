-------------------------------------------------------------------
-- |
-- Module       : Data.Evens
-- Copyright    : (C) 2014
-- License      : BSD-style (see the file etc/LICENSE.md)
-- Maintainer   : Dom De Re
--
-- The "Basics > Even Numbers" demo in the Liquid Demo
--
-- <http://goto.ucsd.edu:8090/index.html>
--
-------------------------------------------------------------------
module Data.Evens where

import LocalPrelude

{-@ type Even = {v:Int | v mod 2 = 0} @-}

{-@ weAreEven :: [Even] @-}
weAreEven :: [Int]
weAreEven = [10, 4, 0, 2, 666]

{-@ notEven :: Even @-}
notEven :: Int
notEven = 6

{-@ isEven :: n:Nat -> {v:Bool | ((Prop v) <=> (n mod 2 = 0))} @-}
isEven   :: Int -> Bool
isEven 0 = True
isEven 1 = False
isEven n = not (isEven (n-1))

{-@ evens :: n:Nat -> [Even] @-}
evens :: Int -> [Int]
evens n = [i | i <- range 0 n, isEven i]

{-@ range :: lo:Int -> hi:Int -> [{v:Int | (lo <= v && v < hi)}] / [hi -lo] @-}
range :: Int -> Int -> [Int]
range lo hi 
  | lo < hi   = lo : range (lo+1) hi
  | otherwise = []
{-@ shift :: [Even] -> Even -> [Even] @-}
shift :: [Int] -> Int -> [Int]
shift xs k = [x + k | x <- xs]

{-@ double :: [Nat] -> [Even] @-}
double :: [Int] -> [Int]
double xs = [x + x | x <- xs]

