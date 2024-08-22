
module Retro.Util where

import Clash.Prelude

-- Chapter 2
data Polarity = High | Low 

newtype Active (p :: Polarity) = MkActive { activeLevel :: Bit }
    deriving (Show, Eq, Ord, Generic, NFDataX, BitPack)

active :: Bit -> Active p
active = MkActive

class IsActive p where
    fromActive :: Active p -> Bool
    toActive :: Bool -> Active p

instance IsActive High where
    fromActive = bitToBool . activeLevel
    toActive = MkActive . boolToBit

instance IsActive Low where
    fromActive = bitToBool . complement . activeLevel
    toActive = MkActive . complement . boolToBit

-- Chapter 4
type HzToPeriod (freq :: Nat) = 1000000000000 `Div` freq
type ClockDivider dom ps = ps `Div` DomainPeriod dom

succIdx :: (Eq a, Enum a, Bounded a) => a -> Maybe a
succIdx x | x == maxBound = Nothing
          | otherwise = Just $ succ x

predIdx :: (Eq a, Enum a, Bounded a) => a -> Maybe a
predIdx x | x == minBound = Nothing
          | otherwise = Just $ pred x

type Seconds        (s  :: Nat) = Milliseconds (1000 * s)
type Milliseconds   (ms :: Nat) = Microseconds (1000 * ms)
type Microseconds   (us :: Nat) = Nanoseconds  (1000 * us)
type Nanoseconds    (ns :: Nat) = Picoseconds  (1000 * ns)
type Picoseconds    (ps :: Nat) = ps
