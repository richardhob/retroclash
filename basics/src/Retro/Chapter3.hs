
module Retro.Chapter3 where

import Clash.Annotations.TH
import Clash.Prelude 

import Retro.Util

exercise2_led :: forall ps dom. (HiddenClockResetEnable dom)
          => KnownNat (ClockDivider dom ps)
          => SNat ps -> Signal dom Bit
exercise2_led _ = boolToBit <$> led
    where cnt = register (0 :: Index (ClockDivider dom ps)) (rollover <$> cnt)
          led = register False (liftA2 check cnt led)
          check a b = if a == 0 
                      then (not b)
                      else b

exercise2 :: forall dom. (HiddenClockResetEnable dom) 
          => (1 <= DomainPeriod dom, KnownNat (DomainPeriod dom))
          => (Signal dom Bit, Signal dom Bit)
exercise2 = (exercise2_led (SNat @(Milliseconds 300)), exercise2_led (SNat @(Milliseconds 500)))

topEntity :: "CLK" ::: Clock System
          -> ("LED1" ::: Signal System Bit
             ,"LED2" ::: Signal System Bit)
topEntity clk = withClockResetEnable clk resetGen enableGen exercise2

makeTopEntity 'topEntity
