module Ranked.Cycle (cycle, up, down) where

import Prelude hiding (cycle)
import Ranked (Line(..))
import System.Random (randomRIO)

-- | Pick a `Line` with probability proportional to its rank. Return
-- the corresponding URL along with the lines where the selected
-- `Line` was moved to the bottom
cycle :: [Line] -> IO (String, [Line])
cycle ls = do
  let weights = map (\(Line _ n) -> max 0 n) ls
      total  = sum weights
  if total <= 0 || null ls
    then return ("", ls)
    else do
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

bump :: (Integer -> Integer) -> Line -> Line
bump f (Line url n) = Line url (f n)

select :: [Integer] -> Integer -> Int
select (w:ws) n
  | n < w     = 0
  | otherwise = 1 + select ws (n - w)
select []     _ = 0