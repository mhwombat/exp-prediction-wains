------------------------------------------------------------------------
-- |
-- Module      :  ALife.Creatur.Wain.Prediction.Daemon
-- Copyright   :  (c) Amy de Buitléir 2013-2015
-- License     :  BSD-style
-- Maintainer  :  amy@nualeargais.ie
-- Stability   :  experimental
-- Portability :  portable
--
-- The daemon that runs the Créatúr experiment.
--
------------------------------------------------------------------------
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
module Main where

import ALife.Creatur (programVersion)
import ALife.Creatur.Daemon (Job(..), launchInteractive)
import ALife.Creatur.Task (runInteractingAgents, simpleJob)
import ALife.Creatur.Wain (programVersion)
import ALife.Creatur.Wain.Prediction.Wain (PredictorWain, run, 
  startRound, finishRound)
import ALife.Creatur.Wain.Prediction.Universe (Universe(..),
  writeToLog, loadUniverse, uSleepBetweenTasks)
import Control.Concurrent (MVar, newMVar, readMVar, swapMVar)
import Control.Lens
import Control.Monad (unless)
import Control.Monad.State (execStateT)
import Data.Version (showVersion)
import Paths_creatur_wains_prediction (version)
import System.IO.Unsafe (unsafePerformIO)

shutdownMessagePrinted :: MVar Bool
{-# NOINLINE shutdownMessagePrinted #-}
shutdownMessagePrinted = unsafePerformIO (newMVar False)

startupHandler :: String -> Universe PredictorWain -> IO (Universe PredictorWain)
startupHandler programName
  = execStateT (writeToLog $ "Starting " ++ programName)

shutdownHandler :: String -> Universe PredictorWain -> IO ()
shutdownHandler programName u = do
  -- Only print the message once
  handled <- readMVar shutdownMessagePrinted
  unless handled $ do
    _ <- execStateT (writeToLog $ "Shutdown requested for "
                      ++ programName) u
    _ <- swapMVar shutdownMessagePrinted True
    return ()

main :: IO ()
main = do
  u <- loadUniverse
  let program = run
  let message = "prediction-wains-" ++ showVersion version
          ++ ", compiled with " ++ ALife.Creatur.Wain.programVersion
          ++ ", " ++ ALife.Creatur.programVersion
          ++ ", configuration=" ++ show u
  let j = simpleJob
        { task=runInteractingAgents program startRound finishRound,
          onStartup=startupHandler message,
          onShutdown=shutdownHandler message,
          sleepTime=view uSleepBetweenTasks u }
  launchInteractive j u