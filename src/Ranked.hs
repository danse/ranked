{-# LANGUAGE NoFieldSelectors #-}

module Ranked
  (Line(..),
   parseLine,
   parseFile,
   serializeLine,
   serializeFile
  )
where

import Text.ParserCombinators.ReadP
import Data.Char (isDigit, isSpace)

data Line = Line {
  location :: String,
  rank :: Int
  } deriving (Eq, Show)

-- Parse the counter part: optional '-', then digits
counterP :: ReadP Int
counterP = do
  sign <- option id (negate <$ char '-')
  n    <- munch1 isDigit
  skipSpaces
  eof
  return $ sign (read n)

-- Parse a single line: the last comma separates URL from counter.
-- If there's no comma, the whole line is the URL with counter 0.
parseLine :: String -> Maybe Line
parseLine s
  | all isSpace s = Nothing
  | otherwise     =
    case breakLastComma s of
      Nothing ->
        -- No comma found — entire line is the URL, counter = 0
        Just (Line s 0)
      Just (url, after) ->
        case readP_to_S counterP after of
          [(n, "")] -> Just (Line url n)
          _         -> Nothing

-- Split a string at the last comma. Returns Nothing if there's no comma.
breakLastComma :: String -> Maybe (String, String)
breakLastComma s =
  case break (== ',') (reverse s) of
    (revAfter, ',':revBefore) -> Just (reverse revBefore, reverse revAfter)
    _                         -> Nothing

serializeLine :: Line -> String
serializeLine (Line url n) = url ++ "," ++ show n

serializeFile :: [Line] -> String
serializeFile = unlines . map serializeLine

parseFile :: String -> Either String [Line]
parseFile = go [] . lines
  where
    go acc []     = Right (reverse acc)
    go acc (l:ls)
      | all isSpace l = go acc ls
      | otherwise     = case parseLine l of
          Just d  -> go (d:acc) ls
          Nothing -> Left $ "parse error on line: " ++ l
