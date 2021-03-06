-------------------------------------------------------------------
-- |
-- Module       : LocalPrelude
-- Copyright    : (C) 2014
-- License      : BSD-style (see the file etc/LICENSE.md)
-- Maintainer   : Dom De Re
--
-- Prelude for this project.
--
-------------------------------------------------------------------
module LocalPrelude (
    -- * Type Classes
        Eq(..)
    ,   Num(..)
    ,   Ord(..)
    ,   Show(..)
    -- * Types
    ,   Bool(..)
    ,   Int
    -- * Operators
    ,   ($)
    ,   (.)
    -- * Functions
    ,   not
    ,   otherwise
    ) where

import Prelude
