
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

-- Throws an error if greater than the max bound
--
-- > (succIdx 38) :: Maybe (Index 40)
-- Just 39
-- > (succIdx 39) :: Maybe (Index 40)
-- Nothing
-- > (succIdx 40) :: Maybe (Index 40)
-- *** Exception: X: Clash.Sized.Index: result 40 is out of bounds [0..39]
succIdx :: (Eq a, Enum a, Bounded a) => a -> Maybe a
succIdx x | x == maxBound = Nothing
          | otherwise = Just $ succ x

-- Throws an error if less than or equal to the min bound
predIdx :: (Eq a, Enum a, Bounded a) => a -> Maybe a
predIdx x | x == minBound = Nothing
          | otherwise = Just $ pred x

type Seconds        (s  :: Nat) = Milliseconds (1000 * s)
type Milliseconds   (ms :: Nat) = Microseconds (1000 * ms)
type Microseconds   (us :: Nat) = Nanoseconds  (1000 * us)
type Nanoseconds    (ns :: Nat) = Picoseconds  (1000 * ns)
type Picoseconds    (ps :: Nat) = ps

-- Throws an error if greater than the max bound. Returns maxBound if the
-- incremented result is equal to the max bound.
moreIdx :: (Eq a, Enum a, Bounded a) => a -> a
moreIdx a = case result of
        Nothing -> maxBound
        Just x -> x
    where result = succIdx a

-- Throws an error if less than the min bound. Returns minBound if the
-- decremented result is equal to the min bound.
lessIdx :: (Eq a, Enum a, Bounded a) => a -> a
lessIdx a = case result of
        Nothing -> minBound
        Just x -> x
    where result = predIdx a

changed :: (HiddenClockResetEnable dom, Eq a, NFDataX a) => a -> Signal dom a -> Signal dom Bool
changed x0 x = x ./=. register x0 x

debounce :: forall ps a dom. (Eq a, NFDataX a) 
         => (HiddenClockResetEnable dom, KnownNat (ClockDivider dom ps)) 
         => SNat ps 
         -> a -> Signal dom a -> Signal dom a
debounce _ start this = regEn start stable this
    where counter = register (0 :: Index (ClockDivider dom ps)) counterNext
          counterNext = mux (changed start this) 0 (moreIdx <$> counter)
          stable = counterNext .==. (pure maxBound)
