
module Retro.Flippy where

import Clash.Prelude hiding (register)
import Clash.Explicit.Prelude (register)

flippy :: Clock System -> Reset System -> Enable System -> Signal System Bool
flippy clk rst en = r
    where r = register clk rst en True (fmap not r)

--
-- in->[r1]->[r2]->out
--     T f   F     F
--     F t   T     F
--     T f   F     T
--     F t   T     T
flippy2 :: Clock System -> Reset System -> Enable System -> Signal System Bool
flippy2 clk rst en = r2
    where r1 = flippy clk rst en
          r2 = register clk rst en True (((not <$> r2) .&&. r1) .||. (r2 .&&. (not <$> r1)))
