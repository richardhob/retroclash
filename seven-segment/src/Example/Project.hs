-- @createDomain@ below generates a warning about orphan instances, but we like
-- our code to be warning-free.
{-# OPTIONS_GHC -Wno-orphans #-}

module Example.Project where

import qualified Data.List as L
import Text.Printf

import Clash.Prelude

-- Create a domain with the frequency of your input clock. For this example we used
-- 50 MHz.
createDomain vSystem{vName="Dom50", vPeriod=hzToPeriod 50e6}

-- | @topEntity@ is Clash@s equivalent of @main@ in other programming languages.
-- Clash will look for it when compiling "Example.Project" and translate it to
-- HDL. While polymorphism can be used freely in Clash projects, a @topEntity@
-- must be monomorphic and must use non- recursive types. Or, to put it
-- hand-wavily, a @topEntity@ must be translatable to a static number of wires.
--
-- Top entities must be monomorphic, meaning we have to specify all type variables.
-- In this case, we are using the @Dom50@ domain, which we created with @createDomain@
-- and we are using 8-bit unsigned numbers.
topEntity ::
  Clock Dom50 ->
  Reset Dom50 ->
  Enable Dom50 ->
  Signal Dom50 (Unsigned 8) ->
  Signal Dom50 (Unsigned 7, Bit)
topEntity = exposeClockResetEnable sevenSegment

-- To specify the names of the ports of our top entity, we create a @Synthesize@ annotation.
{-# ANN topEntity
  (Synthesize
    { t_name = "accum"
    , t_inputs = [ PortName "CLK"
                 , PortName "RST"
                 , PortName "EN"
                 , PortName "DATA"
                 ]
    , t_output = PortProduct "" [PortName "SEGMENTS", PortName "SEL"]
    }) #-}

-- Make sure GHC does not apply any optimizations to the boundaries of the design.
-- For GHC versions 9.2 or older, use: {-# NOINLINE topEntity #-}
{-# OPAQUE topEntity #-}

counter :: (HiddenClockResetEnable dom) => Signal dom (Unsigned 8)
counter = register 100 (reload <$> counter)
    where reload v = if v == 0 then 100 else v - 1

ssSelect :: (HiddenClockResetEnable dom) => Signal dom Bool
ssSelect = register False (liftA2 check ssSelect counter)
    where check v t = if t == 0 then not v else v

iData :: (HiddenClockResetEnable dom) => Signal dom (Unsigned 8) -> Signal dom (Unsigned 4)
iData hexData = register 0 (mux ssSelect (_upper <$> hexData) (_lower <$> hexData))
    where _upper v = truncateB (v .>>. 4) :: Unsigned 4
          _lower v = truncateB v :: Unsigned 4

lookUp :: Unsigned 4 -> Unsigned 7
lookUp v = case v of
      0x0 -> 0b0111111
      0x1 -> 0b0000110
      0x2 -> 0b1011011
      0x3 -> 0b1001111
      0x4 -> 0b1100110
      0x5 -> 0b1101101
      0x6 -> 0b1011111
      0x7 -> 0b0000111
      0x8 -> 0b1111111
      0x9 -> 0b1111011
      0xA -> 0b1110111
      0xB -> 0b1111100
      0xC -> 0b0111001
      0xD -> 0b1011110
      0xE -> 0b1111001
      0xF -> 0b1110001
      _otherwise -> 0b0000000;

-- Convert an Unsigned 8 input into a Dual seven segement output
sevenSegment :: (HiddenClockResetEnable dom)
             => Signal dom (Unsigned 8) 
             -> Signal dom (Unsigned 7, Bit)
sevenSegment hexData = bundle (lookUp    <$> iData hexData
                              ,boolToBit <$> ssSelect)

sevenSegment' :: (HiddenClockResetEnable dom)
              => Signal dom (Unsigned 8) 
              -> (Signal dom (Unsigned 7), Signal dom Bit)
sevenSegment' hexData = (lookUp    <$> iData hexData
                       ,boolToBit <$> ssSelect)

-- Functions for testing only 
printResults :: Unsigned 8 -> Unsigned 7 -> String
printResults = printf "0x%x -> 0b%07b" 

-- Similar to stimultiGenerator From Clash Testbench
-- 
-- https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Explicit-Testbench.html
simIn :: Int -> [Int]
simIn n = L.concat $ [L.replicate n i | i <- [0..]]

-- Take even N samples from the input list
--
-- This is tricky because we have to wait one clock for the input to be 'good'.
everyN :: Int -> [a] -> [a]
everyN _ [] = []
everyN n (x:xs)
    | n <= 1 = x:xs
    | otherwise = x:next
    where next = everyN n (L.drop (n - 1) xs)

doSimulation :: Int -> IO () 
doSimulation n = mapM_ putStrLn (everyN n results)
    where results :: [String]
          results = L.map (uncurry printResults) _zipSim

          testData :: [Unsigned 8]
          testData = L.map fromIntegral $ simIn n

          -- Adding an extra '1' allows us to get the data lines up
          testData' = 1:testData

          _zipSim :: [(Unsigned 8, Unsigned 7)]
          _zipSim = L.zip testData' $ L.map fst _sim

          _sim :: [(Unsigned 7, Bit)]
          _sim = simulateN @System (n * 16) sevenSegment testData'
