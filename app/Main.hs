module Main where

import Prelude hiding (cycle)
import Ranked (parseFile, serializeFile)
import Ranked.Cycle (cycle, up, down)
import Options.Applicative
import System.Exit (exitFailure, exitSuccess)
import Web.Browser (openBrowser)

data Direction = Up | Down | NoDir
  deriving (Eq, Show)

data Opts = Opts
  { optDir     :: Direction
  , optStdout  :: Bool
  , optFile    :: FilePath
  }

opts :: Parser Opts
opts = Opts
  <$> dirOpt
  <*> switch (short 'o' <> help "Write to stdout instead of editing in place")
  <*> argument str (metavar "FILE" <> help "File to process")

dirOpt :: Parser Direction
dirOpt =
  flag' Up (short 'u' <> help "Increment rank of the last visited location")
    <|> flag' Down (short 'd' <> help "Decrement rank of the last visited location")
    <|> pure NoDir

main :: IO ()
main = execParser opts' >>= run
  where
    opts' = info (opts <**> helper)
                 (fullDesc <> progDesc "Parse, adjust ranks, cycle, and open a URL")

run :: Opts -> IO ()
run (Opts dir toStdout file) = do
  content <- readFile file
  let l err = putStrLn ("Error: " ++ err) >> exitFailure
      withPref p = if '.' `elem` p then "https://" <> p else p
      r ds = do
        processed <- case dir of
          Up   -> pure $ up ds
          Down -> pure $ down ds
          NoDir -> do
            (location, cycled) <- cycle ds
            _ <- openBrowser (withPref location)
            pure cycled
        (if toStdout then putStr else writeFile file) (serializeFile processed)
        exitSuccess
  either l r (parseFile content)
