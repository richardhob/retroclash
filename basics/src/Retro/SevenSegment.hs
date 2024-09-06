
module Retro.SevenSegment where

-- This is actually "Seven Segment Revisited" from Chapter 5

import Clash.Prelude

import Retro.Util

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

topEntity :: Clock System
          -> Signal System (Vec 8 Bit) -- Either input switches
          -> ( Signal System (Vec 4 (Active High))
             , Signal System (Vec 7 (Active Low))
             , Signal System (Active Low)
             )
topEntity = withResetEnableGen board 
    where
      board switches = 
          ( map toActive <$> anodes
          , map toActive <$> segments
          , toActive <$> dp
          )
        where
          segments = pure $ repeat True
          dp = pure False

          fast = riseRate (SNat @512)

          slow = fast .&&. cnt .==. 0
            where
              speed = bitCoerce <$> switches
              cnt = regEn (0 :: Unsigned 8) fast $ mux (cnt .>=. speed) 0 (cnt + 1)

          i = regEn 0 slow (nextIdx <$> i)
          anodes = oneHot <$> i
