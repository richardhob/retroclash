
module Retro.Blinky where

import Clash.Annotations.TH
import Clash.Prelude hiding (register)
import Clash.Explicit.Prelude (register)

type SecondPeriods dom = 1000000000000 `Div` DomainPeriod dom

blinkingSecond :: forall dom. (KnownDomain dom)
               => (1 <= DomainPeriod dom, KnownNat (DomainPeriod dom))
               => (1 <= 1000000000000 `Div` (DomainPeriod dom))
               => Clock dom -> Reset dom -> Enable dom -> Signal dom Bit
blinkingSecond clk rst en = msb <$> r
    where r :: Signal dom (Unsigned (CLog 2 (SecondPeriods dom)))
          r = register clk rst en 0 (r+1)

topEntity :: "CLK" ::: Clock System
          -> "LED" ::: Signal System Bit
topEntity clk = blinkingSecond clk resetGen enableGen

makeTopEntity 'topEntity
