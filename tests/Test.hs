module Main where

import Data.Either (isLeft)
import Prelude hiding (cycle)
import Test.Hspec
import Ranked (Line(..), parseLine, parseFile, serializeLine, serializeFile)
import Ranked.Cycle

spec :: Spec
spec = do
  describe "parseLine" $ do
    specify "simple url with positive counter" $
      parseLine "example.com,42" `shouldBe` Just (Line "example.com" 42)

    specify "negative counter" $
      parseLine "foo.com,-3" `shouldBe` Just (Line "foo.com" (-3))

    specify "zero counter" $
      parseLine "zero.com,0" `shouldBe` Just (Line "zero.com" 0)

    specify "url with commas" $
      parseLine "example.com/path?q=a,b,c,42"
        `shouldBe` Just (Line "example.com/path?q=a,b,c" 42)

    specify "line with non-numeric after comma returns Nothing" $
      parseLine "url,abc" `shouldBe` Nothing

    specify "url without any comma defaults to counter 0" $
      parseLine "example.com" `shouldBe` Just (Line "example.com" 0)

  describe "parseFile" $ do
    specify "two lines" $
      parseFile "a.com,1\nb.com,2" `shouldBe` Right [Line "a.com" 1, Line "b.com" 2]

    specify "skips blank lines" $
      parseFile "a.com,1\n\nb.com,2\n  \n"
        `shouldBe` Right [Line "a.com" 1, Line "b.com" 2]

    specify "lines without commas get counter 0" $
      parseFile "a.com,1\nb.com" `shouldBe` Right [Line "a.com" 1, Line "b.com" 0]

    specify "returns Left on parse error" $
      parseFile "a.com,1\nurl,abc\nb.com,2" `shouldSatisfy` isLeft

  describe "serializeLine" $ do
    specify "positive counter" $
      serializeLine (Line "example.com" 42) `shouldBe` "example.com,42"

    specify "zero counter" $
      serializeLine (Line "example.com" 0) `shouldBe` "example.com,0"

    specify "negative counter" $
      serializeLine (Line "example.com" (-3)) `shouldBe` "example.com,-3"

  describe "serializeFile" $ do
    specify "joins with newlines" $
      serializeFile [Line "a.com" 1, Line "b.com" (-2), Line "c.com" 0]
        `shouldBe` "a.com,1\nb.com,-2\nc.com,0\n"

  describe "roundtrip" $ do
    specify "serialize then parse gives original" $
      let l = Line "a.com,with,commas" 42
      in parseLine (serializeLine l) `shouldBe` Just l

  describe "cycle" $ do
    specify "single line returns its URL" $ do
      let ls = [Line "a.com" 5]
      (url, ls') <- cycle ls
      url `shouldBe` "a.com"
      ls' `shouldBe` ls

    specify "selected line moved to bottom" $ do
      let ls = [Line "a.com" 5, Line "b.com" 3, Line "c.com" 1]
      (url, ls') <- cycle ls
      url `shouldSatisfy` (`elem` map (\(Line u _) -> u) ls)
      length ls' `shouldBe` length ls
      not (null ls') `shouldBe` True
      let Line lastUrl _ = last ls'
      lastUrl `shouldBe` url
      init ls' `shouldBe` filter (\(Line u _) -> u /= url) ls

    specify "deterministic with one line" $ do
      let ls = [Line "a.com" 42]
      results <- sequence (replicate 10 (cycle ls))
      all (\(u, _) -> u == "a.com") results `shouldBe` True
      all (\(_, ls') -> ls' == ls) results `shouldBe` True

    specify "works with all negative scores" $ do
      let ls = [Line "a.com" (-5), Line "b.com" (-1), Line "c.com" (-3)]
      (url, ls') <- cycle ls
      url `shouldSatisfy` (`elem` map (\(Line u _) -> u) ls)
      length ls' `shouldBe` length ls

    specify "empty list returns empty" $ do
      (url, ls') <- cycle []
      url `shouldBe` ""
      ls' `shouldBe` []

  describe "up" $ do
    specify "increments last counter" $
      up [Line "a.com" 1, Line "b.com" 5] `shouldBe` [Line "a.com" 1, Line "b.com" 6]

    specify "empty" $
      up [] `shouldBe` []

  describe "down" $ do
    specify "decrements last counter" $
      down [Line "a.com" 1, Line "b.com" 5] `shouldBe` [Line "a.com" 1, Line "b.com" 4]

    specify "empty" $
      down [] `shouldBe` []

  describe "profile" $ do
    specify "sums line ranks with line indexes" $
      let l = [
            Line "a" 0,
            Line "b" 1,
            Line "c" 0,
            Line "d" (-1),
            Line "e" 0]
          p = [5, 5, 3, 1, 1]
      in profile l `shouldBe` p

main :: IO ()
main = hspec spec
