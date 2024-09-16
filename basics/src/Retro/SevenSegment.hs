
module Retro.SevenSegment where

-- This is actually "Seven Segment Revisited" from Chapter 5

import qualified Data.List as L

import Clash.Prelude
import Clash.Annotations.TH

import Retro.Util

-- Chapter 3 Stuff
showSS :: Vec 7 Bool -> String
showSS (a :> b :> c :> d :> e :> f :> g :> Nil) = unlines . L.concat $
    [ L.replicate 1 $ horiz    a   
    , L.replicate 3 $ vert   f   b 
    , L.replicate 1 $ horiz    g   
    , L.replicate 3 $ vert   e   c 
    , L.replicate 1 $ horiz    d   ]
    where horiz True =  " ###### "
          horiz False = " ...... "

          vert b1 b2 = part b1 <> "      " <> part b2
            where part True =  "#"
                  part False = "."

encodeHexSS :: Unsigned 4 -> Vec 7 Bool
encodeHexSS n = unpack $ case n of
    --        abcdefg
    0x0 -> 0b01111110
    0x1 -> 0b00110000
    0x2 -> 0b01101101
    0x3 -> 0b01111001
    0x4 -> 0b00110011
    0x5 -> 0b01011011
    0x6 -> 0b01011111
    0x7 -> 0b01110000
    0x8 -> 0b01111111
    0x9 -> 0b01111011
    0xA -> 0b01110111
    0xB -> 0b00011111
    0xC -> 0b01001110
    0xD -> 0b00111101
    0xE -> 0b01001111
    0xF -> 0b01000111
    _   -> 0b00000000

-- type ClockDivider dom n = n `Div` DomainPeriod dom

-- Generate a pulse every N puleses, based on the provided SNat time. The SNat
-- time is converted into N pulses.
--
-- riseEvery -> Give a pulse every N clock cycles.
risePeriod :: forall ps dom. (HiddenClockResetEnable dom, _)
           => SNat ps -> Signal dom Bool
risePeriod _ = riseEvery (SNat @(ClockDivider dom ps))

-- Generate a pulse every N pulses, based on the provided SNat Frequency. The 
riseRate :: forall rate dom. (HiddenClockResetEnable dom, _)
         => SNat rate -> Signal dom Bool
riseRate _ = risePeriod (SNat @(HzToPeriod rate))

-- One hot encoding! Take an index (i) and select the n-th bit from a vector.
--
-- bitCoerce lets you convert a vector of one size to another
oneHot :: forall n. (KnownNat n) => Index n -> Vec n Bool
oneHot = reverse . bitCoerce . bit @(Unsigned n) . fromIntegral

withResetEnableGen :: (KnownDomain dom) 
                   => (HiddenClockResetEnable dom => r) 
                   -> Clock dom -> r
withResetEnableGen board clk = withClockResetEnable clk resetGen enableGen board

(.!!.) :: (KnownNat n, Enum i, Applicative f) => f (Vec n a) -> f i -> f a
(.!!.) = liftA2 (!!)

-- Update the "Round Robin" index when "Next" is True
roundRobin :: forall n dom. (KnownNat n, HiddenClockResetEnable dom)
           => Signal dom Bool -> (Signal dom (Vec n Bool), Signal dom (Index n))
roundRobin next = (selector, i)
    where i = regEn (0 :: Index n) next $ rollover <$> i
          selector = bitCoerce . oneHot <$> i

-- Rotate throught the output signals (xs) every "tick" cycles.
muxRR :: (KnownNat n, HiddenClockResetEnable dom) 
      => Signal dom Bool -> Signal dom (Vec n a) -> (Signal dom (Vec n Bool), Signal dom a)
muxRR tick xs = (selector, current)
    where (selector, i) = roundRobin tick
          current = xs .!!. i

topEntity :: "CLK" ::: Clock System
          -> "SWITCHES" ::: Signal System (Vec 8 Bit) -- Either input switches
          -> ("ANODES"   ::: Signal System (Vec 4 (Active High)) 
             ,"SEGMENTS" ::: Signal System (Vec 7 (Active Low)) 
             ,"DP"       ::: Signal System (Active Low))
topEntity = withResetEnableGen board 
    where
      board switches = 
          ( map toActive <$> anodes
          , map toActive <$> segments
          , toActive <$> dp
          )
        where
          digits = (repeat Nothing ++) <$> (map Just . bitCoerce <$> switches)
          toSegments = maybe (repeat False) encodeHexSS

          (anodes, segments) = muxRR (riseRate (SNat @512)) $ map toSegments <$> digits
          dp = pure False

makeTopEntity 'topEntity
