{-# LANGUAGE NoImplicitPrelude #-}
module Main where

import Prelude ( Eq(..), Bool, String, ($), (.), (&&) )

import Build_liquid ( specificPackageDBs )
import Control.Applicative
import Control.Monad
import Data.List ( (++), concat, filter, intersperse, isSuffixOf, lines, notElem )
import System.Directory
import System.FilePath
import System.IO ( IO, print )
import System.Process ( readProcess )

packageDBOpts :: [String]
packageDBOpts = (("-g" :). intersperse "-g". fmap ("-package-db=" ++)) specificPackageDBs

liquidOpts :: [FilePath]
liquidOpts = ["--idirs=src"] ++ packageDBOpts

-- the list of all file paths to search for source files
sourceDirs :: [FilePath]
sourceDirs = ["src"]

runLiquid :: FilePath -> IO ()
runLiquid src = do
    print $ "Verifying: " ++ src
    readProcess "liquid" (liquidOpts ++ return src) "" >>= (sequence_ . fmap print . lines)

verify :: [FilePath] -> IO ()
verify = sequence_ . fmap runLiquid

printOutput :: [String] -> IO ()
printOutput = sequence_ . fmap print

main :: IO ()
main = getSources >>= verify

getFilesAndDirectories :: FilePath -> IO ([FilePath], [FilePath])
getFilesAndDirectories dir = do
    c <- fmap (dir </>) . filter (`notElem` ["..", "."]) <$> getDirectoryContents dir
    (,) <$> filterM doesDirectoryExist c <*> filterM doesFileExist c

isSourceFile :: FilePath -> Bool
isSourceFile p = (takeFileName p /= "Setup.hs") && (".hs" `isSuffixOf` p)

getSources :: IO [FilePath]
getSources = liftM (filter isSourceFile . concat) (mapM go sourceDirs)
    where
        go dir = do
            (dirs, files) <- getFilesAndDirectories dir
            (files ++) . concat <$> mapM go dirs
