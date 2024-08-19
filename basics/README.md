# Basics from Retrocomputing with Clash

Retro.First -> BASICs from Chapter 2
Retro.Flippy -> Flippy from Chapter 4

Programming the FPGA with the generated RTL is an exercise left for the readers.

## Generate Verlilog

From the interpreter:

``` haskell
> import Retro.First
> :verilog 
```

From the CLI:

``` bash
> stack run clash -- Retro.First --verilog
```

The CLI option generates the Verilog in a `verilog` folder.

I opted (this time) to NOT copy the sources into the project. So it looks like
you can set up a project to work with the Device specifics, and use Clash to
handle just about everything else.

- [X] Synthesis
- [X] Implementation
- [X] Bitstream
- [X] Program

IT WORKS!!! Button -> LED... ALL DONE. That's not too bad. :) 

## Chapter 3 - 7 Segment display

My FPGA does not have a 7 Segment display, so we will skip the examples here.
Would have loved to have done some of this though.

## Chapter 4 - Sequential Circuits

Registers!!! Explicit registers:

``` haskell
Clash.Explicit.Prelude.register
    :: (KnownDomain dom, NFDataX a)
    => Clock dom        -- Clock signal driving the writing into the register
        -> Reset dom    -- Reset signal that replaces the register value with the initial one
        -> Enable dom   -- Enable / Disable register transfer (False -> don't do)
        -> a            -- Initial value of the register
        -> Signal dom a -- What is written into the register on each tick of the clock
        -> Signal dom a -- Return: aka Output signal
```

Signal the output's True in the first cycle, and False otherwise:

``` haskell
helloRegister :: Clock System -> Reset System -> Enable System -> Signal System Bool
helloRegister clk rst en = register clk rst en True (pure False)
```

"True" is the initial value, and "pure False" is what is written on each tick of
the clock after.

Note that the first two cycles of this circuit are "True" not just one. This is
because of the simulator (which aligns with how the FPGA will behave) - in short
the register outputs True before the first clock. This can be configured in the
clock domain if we want (but we don't really care for this book).

Let's create a more interesting circuit, one that flips between True and False:

``` haskell
flippy :: Clock System -> Reset System -> Enable System -> Signal System Bool
flippy clk rst en = r
    where r = register clk rst en True (not <$> r)
```

Exercise: write a "slow flippy" that goes "True True False False True True ..."

Solution:

``` haskell
flippy2 :: Clock System -> Reset System -> Enable System -> Signal System Bool
flippy2 clk rst en = r2
    where r1 = flippy clk rst en
          r2 = register clk rst en (((not <$> r2) .&&. r1) .||. (r2 .&&. (not <$> r1)))
```

What I was trying to write was:

``` haskell
if r1 == True
then not <$> r2
else r2
```

But `if` statements are not allowed. You have to use boolean logics yo. Which
makes sense. Need to dust off that part of my brain I guess!

Logic in short: toggle the register 2 value if register 1 is true, otherwise
keep the register value the same.

## Chapter 4: Many Blinkys

Starting with 4.3 Blinky - which has issues (Retro.Blinky) - it works!! Kinda
neat. There's some witchcraft going on here I don't *quite* understand, but I'm
sure that it will make more sense in time. :) 

To make it build in Vivado, I had to enable the Clock line in the constraints
file, which was kinda neat! I haven't had to do that before. BUT IT WORKS.
