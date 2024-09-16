
-- | Chapter 5 Assignments
module Retro.Chapter5 where

-- 1. Given the 8 bit input from the switches, display them on three 7-segment
--    displays in decimal
-- 2. Omit leading zeroes in the decimal version
-- 3. At the press of a pushbutton, start and display a countdown (in seconds)
-- 4. Digital stopwatch: one pushbutton to start/stop, one to reset to 0. For
-- extra nicness, compute minutes from the seconds and flash the decimal point
-- between the minutes and the seconds at half second interval

-- 1. Given an 8 bit switches input, display them on three 7 segment displays
--
-- This is tricky because we have to take the switches and convert it into a
-- base 10 number to encode (we can't just use Hex to Binary encoding)
exercise1 :: (HiddenClockResetEnable dom, _)
          => Signal dom (Vec 8 (Active High))
          -> Signal System (SevenSegment 3 High Low Low)
exercise1 switches = let
    encode10 :: Unsigned 4 -> Vec 7 Bool
    encode10 n = unpack $ case n of
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

    value    = register 0 (pack <$> switches)
    ones     = register 0 (value `mod` 10)
    tens     = register 0 (value `div` 10)
    hundreds = register 0 (value `div` 100)

    digits = hundreds :> tens :> ones :> Nil

    -- x has to be in base 10 already
    toSegments x = (encode10 x, False)

    in driveSS toSegments digits