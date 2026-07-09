module Main where

import Prelude hiding (cycle)
import Test.HUnit
import Ranked (Line(..), parseLine, parseFile, serializeLine, serializeFile)
import Ranked.Cycle (cycle, up, down)
import Data.Maybe (isNothing)
import System.Exit (exitFailure, exitSuccess)

testParseSimple :: Test
testParseSimple = TestCase $
  assertEqual "simple url with positive counter"
    (Just (Line "example.com" 42))
    (parseLine "example.com,42")

testParseNegative :: Test
testParseNegative = TestCase $
  assertEqual "negative counter"
    (Just (Line "foo.com" (-3)))
    (parseLine "foo.com,-3")

testParseZero :: Test
testParseZero = TestCase $
  assertEqual "zero counter"
    (Just (Line "zero.com" 0))
    (parseLine "zero.com,0")

testParseUrlWithCommas :: Test
testParseUrlWithCommas = TestCase $
  assertEqual "url with commas"
    (Just (Line "example.com/path?q=a,b,c" 42))
    (parseLine "example.com/path?q=a,b,c,42")

testParseInvalid :: Test
testParseInvalid = TestCase $
  assertBool "line with non-numeric after comma returns Nothing" (isNothing (parseLine "url,abc"))

testParseFileMultipleLines :: Test
testParseFileMultipleLines = TestCase $
  assertEqual "two lines"
    (Right [Line "a.com" 1, Line "b.com" 2])
    (parseFile "a.com,1\nb.com,2")

testParseFileWithBlankLines :: Test
testParseFileWithBlankLines = TestCase $
  assertEqual "skips blank lines"
    (Right [Line "a.com" 1, Line "b.com" 2])
    (parseFile "a.com,1\n\nb.com,2\n  \n")

testParseUrlNoComma :: Test
testParseUrlNoComma = TestCase $
  assertEqual "url without any comma defaults to counter 0"
    (Just (Line "example.com" 0))
    (parseLine "example.com")

testParseLineNoCommaInFile :: Test
testParseLineNoCommaInFile = TestCase $
  assertEqual "lines without commas get counter 0"
    (Right [Line "a.com" 1, Line "b.com" 0])
    (parseFile "a.com,1\nb.com")

testSerializeLine :: Test
testSerializeLine = TestCase $
  assertEqual "serialize positive counter" "example.com,42"
    (serializeLine (Line "example.com" 42))

testSerializeLineZero :: Test
testSerializeLineZero = TestCase $
  assertEqual "serialize zero counter" "example.com,0"
    (serializeLine (Line "example.com" 0))

testSerializeLineNegative :: Test
testSerializeLineNegative = TestCase $
  assertEqual "serialize negative counter" "example.com,-3"
    (serializeLine (Line "example.com" (-3)))

testSerializeRoundtrip :: Test
testSerializeRoundtrip = TestCase $ do
  let l = Line "a.com,with,commas" 42
  assertEqual "serialize then parse gives original" (Just l) (parseLine (serializeLine l))

testSerializeFile :: Test
testSerializeFile = TestCase $
  assertEqual "serializeFile joins with newlines"
    "a.com,1\nb.com,-2\nc.com,0\n"
    (serializeFile [Line "a.com" 1, Line "b.com" (-2), Line "c.com" 0])

testCycleSingle :: Test
testCycleSingle = TestCase $ do
  let ls = [Line "a.com" 5]
  (url, ls') <- cycle ls
  assertEqual "single line returns its URL" "a.com" url
  assertEqual "single line list unchanged" ls ls'

testCycleSelectedMovedToBottom :: Test
testCycleSelectedMovedToBottom = TestCase $ do
  let ls = [Line "a.com" 5, Line "b.com" 3, Line "c.com" 1]
  (url, ls') <- cycle ls
  assertBool "selected url is one of the input urls"
    (url `elem` map (\(Line u _) -> u) ls)
  assertEqual "list length preserved" (length ls) (length ls')
  -- the selected line should be at the bottom
  assertBool "list not empty" (not (null ls'))
  let lastUrl = let (Line u _) = last ls' in u
  assertEqual "selected line moved to bottom" url lastUrl
  -- the remaining lines should be in the same relative order
  let initLines' = init ls'
      expectedInit = filter (\(Line u _) -> u /= url) ls
  assertEqual "other lines keep order" expectedInit initLines'

testCycleDeterministicWithOneLine :: Test
testCycleDeterministicWithOneLine = TestCase $ do
  let ls = [Line "a.com" 42]
  results <- sequence (replicate 10 (cycle ls))
  assertBool "always same URL" (all (\(u, _) -> u == "a.com") results)
  assertBool "always same list" (all (\(_, ls') -> ls' == ls) results)

testCycleEmpty :: Test
testCycleEmpty = TestCase $ do
  (url, ls') <- cycle []
  assertEqual "empty list returns empty URL" "" url
  assertEqual "empty list returns empty list" [] ls'

testUp :: Test
testUp = TestCase $ do
  let ls = [Line "a.com" 1, Line "b.com" 5]
      ls' = up ls
  assertEqual "up increments last counter" [Line "a.com" 1, Line "b.com" 6] ls'

testUpEmpty :: Test
testUpEmpty = TestCase $
  assertEqual "up empty" [] (up [])

testDown :: Test
testDown = TestCase $ do
  let ls = [Line "a.com" 1, Line "b.com" 5]
      ls' = down ls
  assertEqual "down decrements last counter" [Line "a.com" 1, Line "b.com" 4] ls'

testDownEmpty :: Test
testDownEmpty = TestCase $
  assertEqual "down empty" [] (down [])

testParseFileWithErrors :: Test
testParseFileWithErrors = TestCase $
  assertBool "returns Left on parse error"
    (case parseFile "a.com,1\nurl,abc\nb.com,2" of
       Left _ -> True
       Right _ -> False)

tests :: Test
tests = TestList [ TestLabel "testParseSimple" testParseSimple
                 , TestLabel "testParseNegative" testParseNegative
                 , TestLabel "testParseZero" testParseZero
                 , TestLabel "testParseUrlWithCommas" testParseUrlWithCommas
                 , TestLabel "testParseInvalid" testParseInvalid
                 , TestLabel "testParseFileMultipleLines" testParseFileMultipleLines
                 , TestLabel "testParseFileWithBlankLines" testParseFileWithBlankLines
                 , TestLabel "testParseUrlNoComma" testParseUrlNoComma
                 , TestLabel "testParseLineNoCommaInFile" testParseLineNoCommaInFile
                 , TestLabel "testSerializeLine" testSerializeLine
                 , TestLabel "testSerializeLineZero" testSerializeLineZero
                 , TestLabel "testSerializeLineNegative" testSerializeLineNegative
                 , TestLabel "testSerializeRoundtrip" testSerializeRoundtrip
                 , TestLabel "testSerializeFile" testSerializeFile
                 , TestLabel "testCycleSingle" testCycleSingle
                 , TestLabel "testCycleSelectedMovedToBottom" testCycleSelectedMovedToBottom
                 , TestLabel "testCycleDeterministicWithOneLine" testCycleDeterministicWithOneLine
                 , TestLabel "testCycleEmpty" testCycleEmpty
                 , TestLabel "testUp" testUp
                 , TestLabel "testUpEmpty" testUpEmpty
                 , TestLabel "testDown" testDown
                 , TestLabel "testDownEmpty" testDownEmpty
                 , TestLabel "testParseFileWithErrors" testParseFileWithErrors
                 ]

main :: IO ()
main = do
  results <- runTestTT tests
  if failures results > 0 || errors results > 0
    then exitFailure
    else exitSuccess