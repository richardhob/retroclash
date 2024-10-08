-- | Chapter 5 Assignments
module Retro.Chapter5 where

import Clash.Prelude

import Retro.Util
import Retro.SevenSegment

encode10 :: Unsigned 4 -> Vec 7 Bool
encode10 n = unpack $ case n of
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
    _   -> 0b00000000

-- Create Switches for testing
--
-- > let x = (toActive <$> (repeat False)) :: Vec 8 (Active High)

-- Exercises
-- ---------
--
-- 4. Digital stopwatch: one pushbutton to start/stop, one to reset to 0. For
-- extra nicness, compute minutes from the seconds and flash the decimal point
-- between the minutes and the seconds at half second interval

-- Exercise 1
-- ---------
-- Given an 8 bit switches input, display them on three 7 segment displays
--
-- This is tricky because we have to take the switches and convert it into a
-- base 10 number to encode (we can't just use Hex to Binary encoding)
--
exercise1 :: (HiddenClockResetEnable dom, _)
          => Signal dom (Vec 8 (Active High))
          -> Signal dom (SevenSegment 3 High Low Low)
exercise1 switches = let
    digits :: forall dom. (HiddenClockResetEnable dom) 
           => Signal dom (Vec 8 (Active High)) -> Signal dom (Vec 3 (Maybe (Unsigned 4)))
    digits s = doWork <$> s
        where doWork :: Vec 8 (Active High) -> Vec 3 (Maybe (Unsigned 4))
              doWork sw = hundreds :> tens :> ones :> Nil
                  where value    = pack sw
                        ones     = Just (to4 $ value `mod` 10)
                        tens     = Just (to4 $ value `div` 10)
                        hundreds = Just (to4 $ value `div` 100)

    to4 :: BitVector 8 -> Unsigned 4
    to4 = bitCoerce . truncateB 

    toSegments x = (encode10 x, False)

    in driveSS toSegments (digits switches)

-- Exercise 2
-- ---------
-- Omit leading zeroes in the decimal version
--
-- Tricky! We could possibly change up the `encode10` to validate our input ...
-- Actually, we can just update our `digits` definition to check if the `tens`
-- or `hundreds` is 0
exercise2 :: (HiddenClockResetEnable dom, _)
          => Signal dom (Vec 8 (Active High))
          -> Signal dom (SevenSegment 3 High Low Low)
exercise2 switches = let
    digits :: forall dom. (HiddenClockResetEnable dom) 
           => Signal dom (Vec 8 (Active High)) -> Signal dom (Vec 3 (Maybe (Unsigned 4)))
    digits s = doWork <$> s
        where doWork :: Vec 8 (Active High) -> Vec 3 (Maybe (Unsigned 4))
              doWork sw = m_hundreds :> m_tens :> ones :> Nil
                  where value    = pack sw
                        ones     = Just (to4 $ value `mod` 10)

                        tens     = to4 $ value `div` 10
                        m_tens   = if tens == 0 then Nothing else (Just tens)

                        hundreds = to4 $ value `div` 100
                        m_hundreds = if hundreds == 0 then Nothing else (Just hundreds)

    to4 :: BitVector 8 -> Unsigned 4
    to4 = bitCoerce . truncateB 

    toSegments x = (encode10 x, False)

    in driveSS toSegments (digits switches)

downCounter :: forall dom. (HiddenClockResetEnable dom)
            => Unsigned 8 -> Signal dom (Vec 8 Bit)
downCounter n = (bv2v . pack) <$> dc 
    where dc = register n (dc - 1)

to4 :: BitVector 8 -> Unsigned 4
to4 = bitCoerce . truncateB 

toDigits :: forall dom. (HiddenClockResetEnable dom)
         => Vec 8 Bit -> Vec 3 (Maybe (Unsigned 4))
toDigits sw = m_hundreds :> m_tens :> ones :> Nil
    where value    = pack sw
          ones     = Just (to4 $ value `mod` 10)

          tens     = to4 $ value `div` 10
          m_tens   = if tens == 0 then Nothing else (Just tens)

          hundreds = to4 $ value `div` 100
          m_hundreds = if hundreds == 0 then Nothing else (Just hundreds)

-- Exercise 3
-- ----------
-- At the press of a pushbutton, start and display a countdown (in seconds)
--
-- OK COOL! So here we have to take exercise 2, and update it to display the
-- value from a counter instead of from some switches (which is so cool).
--
-- I am skipping the switch for now and just implementing the down counter. We
-- can modifiy the `downCounter` to count every second using a regEn. We can
-- then determine if the down counter is down by checking if the value is 0.
exercise3 :: forall dom. (HiddenClockResetEnable dom)
          => Signal dom (SevenSegment 3 High Low Low)
exercise3 = driveSS toSegments (toDigits <$> downCounter 10)
    where toSegments x = (encode10 x, False)
