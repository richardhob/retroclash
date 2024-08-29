
module Retro.Blinky where

-- Questions
-- 
-- - What is the (1 <= ...) line doing here?
-- - CLog 2 X is a logarithm function from the prelude?
--   --
-- - snatToNum?
--   -- Convert a 'Type' value to a normal value?
-- - SNat @(ClockDivider dom (HzToPeriod 1) -> WHAT
--   -- Singleton Natural?
--   -- Maybe this is required to convert "ClockDivider dom HzToPeriod 1" to a
--      value that can be used NOT in types? Since HzToPeriod is usable in
--      types...
--   -- Perhaps SNat is the "Typelevel" Nat. To Use SNat in Nat you need to
--      "snatToNum"
--   

import Clash.Annotations.TH
import Clash.Prelude 

import Retro.Util

-- createDomain vSystem{vName="Dom100", vPeriod=hzToPeriod 100_000_000}

data OnOff on off = On (Index on)
                  | Off (Index off)
                  deriving (Generic, NFDataX)

isOn :: OnOff on off -> Bool
isOn On{} = True
isOn Off{} = False

countOnOff :: (KnownNat on, KnownNat off) => OnOff on off -> OnOff on off
countOnOff (On  x) = maybe (Off 0) On  $ succIdx x
countOnOff (Off y) = maybe (On  0) Off $ succIdx y

-- blinkingSecond :: forall dom. (HiddenClockResetEnable dom, _) => Signal dom Bit
-- blinkingSecond = boolToBit . isOn <$> r
    -- where r :: Signal dom (OnOff (ClockDivider dom (Milliseconds 500)) 
                                 -- (ClockDivider dom (Milliseconds 500)))
          -- r = register (Off 0) $ countOnOff <$> r
 
-- topEntity :: "CLK100MHZ" ::: Clock Dom100
          -- -> "LED" ::: Signal Dom100 Bit
-- topEntity clk = withClockResetEnable clk resetGen enableGen blinkingSecond
-- makeTopEntity 'topEntity

-- Exercises 
-- 1. Blink only a set number of times
-- 2. Blink multiple LEDs at different speeds
-- 3. Sychronized LED Blinking. Write fun patters like a left-to-right then
--    right-to-left sweep. Or sweep from both sides to the center then outwards
--    again
-- 4. Sequence multiple LED blinking patters, each one shown for a couple of
--    seconds before switching to the next one
-- exercise1 :: forall dom. (HiddenClockResetEnable dom, _) => Signal dom Bit
-- exercise1 = boolToBit . isOn <$> blink
    -- where blink :: Signal dom (OnOff (ClockDivider dom (Milliseconds 500))
                                     -- (ClockDivider dom (Milliseconds 500)))
          -- blink = regEn (Off 0) ((< 10) <$> counter) (countOnOff <$> blink)
-- 
          -- counter :: Signal dom Int
          -- counter = x 
              -- where x = register 0 ((maybeIncrement <$> blink) <*> x)
                    -- maybeIncrement (On v) = if v == 1 then ((+) 1) else ((+) 0)
                    -- maybeIncrement (Off _) = ((+) 0)
--
topEntity :: "CLK"    ::: Clock  System
          -> "BUTTON" ::: Signal System (Active High)
          -> "LED"    ::: Signal System (Active High)
topEntity clk = withClockResetEnable clk resetGen enableGen board
    where board button  = toActive <$> led
            where button' = debounce (SNat @(Milliseconds 5)) False (fromActive <$> button)
                  click = isRising False button'
                  led = regEn False click (not <$> led)

makeTopEntity 'topEntity
