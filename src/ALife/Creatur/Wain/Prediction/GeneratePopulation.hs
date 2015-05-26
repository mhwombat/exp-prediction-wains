------------------------------------------------------------------------
-- |
-- Module      :  ALife.Creatur.Wain.Prediction.GeneratePopulation
-- Copyright   :  (c) Amy de Buitléir 2012-2015
-- License     :  BSD-style
-- Maintainer  :  amy@nualeargais.ie
-- Stability   :  experimental
-- Portability :  portable
--
-- ???
--
------------------------------------------------------------------------
{-# LANGUAGE TypeFamilies #-}

import ALife.Creatur (agentId)
import ALife.Creatur.Wain.Prediction.Wain (PredictorWain,
  randomPredictorWain, printStats)
import ALife.Creatur.Wain (adjustEnergy)
import ALife.Creatur.Wain.Pretty (pretty)
import ALife.Creatur.Wain.PersistentStatistics (clearStats)
import ALife.Creatur.Wain.Statistics (Statistic, stats, summarise)
import ALife.Creatur.Wain.Prediction.Universe (Universe(..),
  writeToLog, store, loadUniverse, uClassifierSizeRange,
  uDeciderSizeRange, uInitialPopulationSize, uStatsFile)
import Control.Lens
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Random (evalRandIO)
import Control.Monad.Random.Class (getRandomR)
import Control.Monad.State.Lazy (StateT, evalStateT, get)

introduceRandomAgent
  :: String -> StateT (Universe PredictorWain) IO [Statistic]
introduceRandomAgent name = do
  u <- get
  classifierSize
    <- liftIO . evalRandIO . getRandomR . view uClassifierSizeRange $ u
  deciderSize
    <- liftIO . evalRandIO . getRandomR . view uDeciderSizeRange $ u
  agent
    <- liftIO . evalRandIO $
        randomPredictorWain name u classifierSize deciderSize
  -- Make the first generation a little hungry so they start learning
  -- immediately.
  let (agent', _, _) = adjustEnergy 0.8 agent
  writeToLog $ "GeneratePopulation: Created " ++ agentId agent'
  writeToLog $ "GeneratePopulation: Stats " ++ pretty (stats agent')
  store agent'
  return (stats agent')

introduceRandomAgents
  :: [String] -> StateT (Universe PredictorWain) IO ()
introduceRandomAgents ns = do
  xs <- mapM introduceRandomAgent ns
  let yss = summarise xs
  printStats yss
  statsFile <- use uStatsFile
  clearStats statsFile
  
main :: IO ()
main = do
  u <- loadUniverse
  let ns = map (("Founder" ++) . show) [1..(view uInitialPopulationSize u)]
  print ns
  evalStateT (introduceRandomAgents ns) u
  