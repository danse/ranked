{-# LANGUAGE OverloadedRecordDot #-}
module Ranked.Cycle (cycle, up, down, profile) where

import Prelude hiding (cycle)
import Ranked (Line(..))
import System.Random (randomRIO)

-- | Pick a `Line` with probability proportional to its rank. Return
-- the corresponding URL along with the lines where the selected
-- `Line` was moved to the bottom
cycle :: [Line] -> IO (String, [Line])
cycle ls = do
  if null ls
    then return ("", ls)
    else do
      let raw = profile ls
          shift = if minimum raw < 0 then -(minimum raw) + 1 else 0
          weights = map (\n -> n + shift) raw
          total  = sum weights
      pick <- randomRIO (0, total - 1)
      let idx = select weights pick
          (Line url _) = ls !! idx
          moved = take idx ls ++ drop (idx + 1) ls ++ [ls !! idx]
      return (url, moved)

-- | Increment the counter of the last `Line` (the one most recently
-- cycled to the bottom)
up :: [Line] -> [Line]
up []     = []
up ls     = init ls ++ [bump (+1) (last ls)]

-- | Decrement the counter of the last `Line`
down :: [Line] -> [Line]
down []   = []
down ls   = init ls ++ [bump (+(-1)) (last ls)]

bump :: (Int -> Int) -> Line -> Line
bump f (Line url n) = Line url (f n)

select :: [Int] -> Int -> Int
select (w:ws) n
  | n < w     = 0
  | otherwise = 1 + select ws (n - w)
select []     _ = 0

-- | Gather rank profile taking into account line rank and index
profile :: [Line] -> [Int]
profile = reverse . map g . zip [(1 :: Int)..] . reverse
  where
    g :: (Int, Line) -> Int
    g (i, l) =  l.rank + i
