# Seven Segment Display

On of the best places to start with an FPGA (after blinky) is the Seven Segement
display. The example in the book is a bit different than the hardware I have,
and I'd A LOT DUMBER than the author of this book so I need to do things a bit
slower.

## PMOD Dual 7-Segment

- [Product in Digilent Shop](https://digilent.com/shop/pmod-ssd-seven-segment-display/)
- [Reference Manual](https://digilent.com/reference/pmod/pmodssd/reference-manual?redirect=1)

## Pinout 

| Header | Pin | Signal | Description                           |
| ------ | --- | ------ | -----------                           |
| J1     | 1   | AA     | Segment A                             |
| J1     | 2   | AB     | Segment B                             |
| J1     | 3   | AD     | Segment C                             |
| J1     | 4   | AD     | Segment C                             |
| J1     | 5   | GND    | Power Supply Ground                   |
| J1     | 6   | VCC    | Positive Power Supply                 |
| J2     | 1   | AE     | Segment E                             |
| J2     | 2   | AF     | Segment F                             |
| J2     | 3   | AG     | Segment G                             |
| J2     | 4   | C      | Digit Selection Pin                   |
| J2     | 5   | GND    | Power Supply Ground                   |
| J2     | 6   | VCC    | Postive Power Supply                  |

Note that DP (IE the decimal point) is not addressable in this hardware.

Also note that the two seven segment display share the segment input pins, and
can be swapped using the J2 pin 4 (C).

## Segments

```
     A
   ----- 
  |     |
 F|     |B
  |  G  |
   -----
  |     |
 E|     |C
  |  D  |  
   -----  ()DP
```

## Encoding

| Value (Hex) | 7 Segment Output (Binary) |
| ----------- | ------------------------- |
| -           | 0bgfedcba                 |
| 0x00        | 0b0111111                 |
| 0x01        | 0b0000110                 |
| 0x02        | 0b1011011                 |
| 0x03        | 0b1001111                 |
| 0x04        | 0b1100110                 |
| 0x05        | 0b1101101                 |
| 0x06        | 0b1011111                 |
| 0x07        | 0b0000111                 |
| 0x08        | 0b1111111                 |
| 0x09        | 0b1111011                 |
| 0x0A        | 0b1110111                 |
| 0x0B        | 0b1111100                 |
| 0x0C        | 0b0111001                 |
| 0x0D        | 0b1011110                 |
| 0x0E        | 0b1111001                 |
| 0x0F        | 0b1110001                 |

## Project Description

The goal of this project is to convert a 8 bit unsigned Hex number, and display
it on the dual seven segment display. I am sure there are many ways to complete
this. 

IP Pins:

- Input -> Clock Signal
- Input -> Reset signal
- Input -> Enable Signal
- Input -> Data (8 bits, unsigned)
- Output -> Segment (7 bits, unsigned)
- Output -> Display Select Signal (High or Low)

How I figure this will work best:

- Invert the Dispaly Select Signal every N clock (using a Timer)
- Use the Display Select Signal internally to swap the data lines for the
  display (Upper nibble, Lower nibble)
- Conver the nibble of data into Seven Segment output

### Verilog

Let's start with a Verilog version of this:

``` verilog
module SevenSegment(input wire CLK,
                    input wire RST,
                    input wire EN,
                    input wire [7:0] DATA,
                    output reg [6:0] SEGMENTS,
                    output reg SEL);

    // Number of clocks between display swap
    parameter THRESHOLD = 100;

    reg [15:0] iCOUNTER;
    initial iCOUNTER = 0;

    // Down Counter 
    always @(posedge CLK)
        if (RST) 
            iCOUNTER <= THRESHOLD;
        else if (EN)
            if (iCOUNTER > 0)
                iCOUNTER <= iCOUNTER - 1;
            else // iCOUNTER == 0
                iCOUNTER <= THRESHOLD;

    // SEL
    always @(posedge CLK)
        if (RST)
            SEL <= 0;
        else if (EN)
            if (iCOUNTER == 0)
                SEL <= ~SEL;

    reg [3:0] iDATA = 0;
    initial iDATA = 0;

    // DATA -> iDATA
    always @(posedge CLK)
        if (RST)
            iDATA <= 0;
        else if (EN)
            if (SEL)
                iDATA <= DATA[7:4];
            else
                iDATA <= DATA[3:0];

    // iDATA -> SEGMENTS
    always @(posedge CLK)
        begin
            if (RST)
                SEGMENTS <= 7'b0000000;
            else if (EN)
                case (iDATA)
                    4'h0: SEGMENTS <= 7'b0111111;
                    4'h1: SEGMENTS <= 7'b0000110;
                    4'h2: SEGMENTS <= 7'b1011011;
                    4'h3: SEGMENTS <= 7'b1001111;
                    4'h4: SEGMENTS <= 7'b1100110;
                    4'h5: SEGMENTS <= 7'b1101101;
                    4'h6: SEGMENTS <= 7'b1011111;
                    4'h7: SEGMENTS <= 7'b0000111;
                    4'h8: SEGMENTS <= 7'b1111111;
                    4'h9: SEGMENTS <= 7'b1111011;
                    4'hA: SEGMENTS <= 7'b1110111;
                    4'hB: SEGMENTS <= 7'b1111100;
                    4'hC: SEGMENTS <= 7'b0111001;
                    4'hD: SEGMENTS <= 7'b1011110;
                    4'hE: SEGMENTS <= 7'b1111001;
                    4'hF: SEGMENTS <= 7'b1110001;
                endcase
        end

endmodule
```

Pretty simple! Let's write a test bench in Verilator to make sure this works as
expected.

### Verilator

How to handle Tick in Verilator (as recommended by ZipCpu):

``` cpp
void tick(VSevenSegment* tb, VerilatedVcdC* trace) 
{
    static uint32_t tick = 1;
    tb->eval();

    if (trace) trace->dump(tick * 10 - 2);

    tb->CLK = 1;
    tb->eval();

    // 10ns Tick 
    if (trace) trace->dump(tick * 10);
    
    tb->CLK = 0;
    tb->eval();

    // Trailing Edge
    if (trace) 
    {
        trace->dump(tick * 10 + 5);
        trace->flush();
    }

    tick = tick + 1;
}
```

How I am handling Reset:

``` cpp
void reset(VSevenSegment* tb, VerilatedVcdC* trace)
{
    tb->RST = 1;

    tick(tb, trace);
    tick(tb, trace);

    tb->RST = 0;
}
```

Cursed MAGIC to convert our Byte into Binary:

``` cpp
// Hacky stuff from:
//     https://stackoverflow.com/questions/111928/is-there-a-printf-converter-to-print-in-binary-format
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  ((byte) & 0x80 ? '1' : '0'), \
  ((byte) & 0x40 ? '1' : '0'), \
  ((byte) & 0x20 ? '1' : '0'), \
  ((byte) & 0x10 ? '1' : '0'), \
  ((byte) & 0x08 ? '1' : '0'), \
  ((byte) & 0x04 ? '1' : '0'), \
  ((byte) & 0x02 ? '1' : '0'), \
  ((byte) & 0x01 ? '1' : '0') 
```

Our test bench:

``` cpp
int main(int argc, char ** argv) 
{
    Verilated::commandArgs(argc, argv);

    VSevenSegment *tb = new VSevenSegment;

    Verilated::traceEverOn(true);
    VerilatedVcdC* trace = new VerilatedVcdC;
    tb->trace(trace, 99);
    trace->open("waveform.vcd");

    // Set the default values
    tb->CLK = 0;
    tb->RST = 0;

    // Reset
    reset(tb, trace);

    // Ready!
    tb->EN = 1;
    tick(tb, trace);

    for(int i = 0; i <= 0xF; i++)
    {
        tb->DATA = i;
        tick(tb, trace);
        tick(tb, trace);
        printf("0x%x -> 0b"BYTE_TO_BINARY_PATTERN, tb->DATA, BYTE_TO_BINARY(tb->SEGMENTS));
        printf("\n");
    }
}
```

This shows the HEX to SEGMENTS conversion in the cosole:

``` bash
> ./obj_dir/VSevenSegment
0x0 -> 0b00111111
0x1 -> 0b00000110
0x2 -> 0b01011011
0x3 -> 0b01001111
0x4 -> 0b01100110
0x5 -> 0b01101101
0x6 -> 0b01011111
0x7 -> 0b00000111
0x8 -> 0b01111111
0x9 -> 0b01111011
0xa -> 0b01110111
0xb -> 0b01111100
0xc -> 0b00111001
0xd -> 0b01011110
0xe -> 0b01111001
0xf -> 0b01110001
```

Pretty neat! Timing:

TODO: Timing diagram

### Clash

So we have a test bench, and an implementation in Verilog. Let's write the same
thing in Clash, and make sure it passes our tests.

First, the BORING bits (but super necessary):

``` haskell
import Clash.Prelude

-- Create a domain with the frequency of your input clock (50 MHz)
createDomain vSystem{vName="Dom50", vPeriod=hzToPeriod 50e6}

topEntity ::
  Clock Dom50 ->
  Reset Dom50 ->
  Enable Dom50 ->
  Signal Dom50 (Unsigned 8) ->
  Signal Dom50 (Unsigned 7, Bit)
topEntity = exposeClockResetEnable sevenSegment

-- Name our input and output signal
{-# ANN topEntity
  (Synthesize
    { t_name = "accum"
    , t_inputs = [ PortName "CLK"
                 , PortName "RST"
                 , PortName "EN"
                 , PortName "DATA"
                 ]
    , t_output = PortProduct "" [PortName "SEGMENTS", PortName "SEL"]
    }) #-}

-- Prevent GHC from optimizing things
{-# OPAQUE topEntity #-}
```

Now for the stuff that mirrors our Verilog:

``` haskell
counter :: (HiddenClockResetEnable dom) => Signal dom (Unsigned 8)
counter = register 100 (reload <$> counter)
    where reload v = if v == 0 then 100 else v - 1

ssSelect :: (HiddenClockResetEnable dom) => Signal dom Bool
ssSelect = register False (liftA2 check ssSelect counter)
    where check v t = if t == 0 then not v else v

iData :: (HiddenClockResetEnable dom) => Signal dom (Unsigned 8) -> Signal dom (Unsigned 4)
iData hexData = register 0 (mux ssSelect (_upper <$> hexData) (_lower <$> hexData))
    where _upper v = truncateB (v .>>. 4) :: Unsigned 4
          _lower v = truncateB v :: Unsigned 4

lookUp :: Unsigned 4 -> Unsigned 7
lookUp v = case v of
      0x0 -> 0b0111111
      0x1 -> 0b0000110
      0x2 -> 0b1011011
      0x3 -> 0b1001111
      0x4 -> 0b1100110
      0x5 -> 0b1101101
      0x6 -> 0b1011111
      0x7 -> 0b0000111
      0x8 -> 0b1111111
      0x9 -> 0b1111011
      0xA -> 0b1110111
      0xB -> 0b1111100
      0xC -> 0b0111001
      0xD -> 0b1011110
      0xE -> 0b1111001
      0xF -> 0b1110001
      _otherwise -> 0b0000000;

-- Convert an Unsigned 8 input into a Dual seven segement output
sevenSegment :: (HiddenClockResetEnable dom)
             => Signal dom (Unsigned 8) 
             -> Signal dom (Unsigned 7, Bit)
sevenSegment hexData = bundle (lookUp    <$> iData hexData
                              ,boolToBit <$> ssSelect)
```

### Verilate the Clash Output

### Tests in Clash

We can also test our built Clash function in Clash. 

We need a function to print the results:

``` haskell
import Text.Printf

printResults :: Int -> Int -> String
printResults = printf "0x%x -> 0b%07b" 
```

And a way to create our simulation input:

``` haskell
import qualified Data.List as L
simIn :: Int -> [Int]
simIn n = L.concat $ [L.replicate n i | i <- [0..]]
```

And finally a way to only print every few outputs:

``` haskell
everyN :: Int -> [Int] -> [Int]
everyN _ [] = []
everyN n (x:xs)
    | n <= 1 = x:xs
    | otherwise = x:next
    where next = everyN n (L.drop (n - 1) xs)
```

``` haskell
clashi> import Example.Project
clashi> import Text.Printf
clashi> let x = simulateN @System 32 sevenSegment [0..]
clashi> 
```

------

**__ASSIDE__** Why Bundle the Seven Segment Output? It makes it easier to
simulate.

``` haskell
sevenSegment' :: (HiddenClockResetEnable dom)
              => Signal dom (Unsigned 8) 
              -> (Signal dom (Unsigned 7), Signal dom Bit)
sevenSegment' hexData = (lookUp <$> iData hexData, boolToBit <$> ssSelect)
```

`sevenSegement'` is functionally the same as `sevenSegment`, but the output
signals are NOT bundled. What happens when we try to simulate this?

``` bash
clashi> simulate @System sevenSegement' [0..32]
<interactive>:16:18: error:
    • Couldn't match type: (Signal System (Unsigned 7),
                            Signal System Bit)
                     with: Signal System b
      Expected: Signal System (Unsigned 8) -> Signal System b
        Actual: Signal System (Unsigned 8)
                -> (Signal System (Unsigned 7), Signal System Bit)
    • In the second argument of ‘simulate’, namely ‘sevenSegment’
      In the expression: simulate @System sevenSegment [1 .. 16]
      In an equation for ‘it’:
          it = simulate @System sevenSegment [1 .. 16]
    • Relevant bindings include it :: [b] (bound at <interactive>:16:1)
```

We _could_ use `simulateB` instead to do this:

``` haskell
clashi> simulateB @System sevenSegment' [0..32]
[(63,0),(63,0),(6,0),(91,0),(79,0),(102,0),(109,0),(95,0),(7,0),(127,0),(123,0),(119,0),(124,0),(57,0),(9
4,0),(121,0),(113,0),(63,0),(6,0),(91,0),(79,0),(102,0),(109,0),(95,0),(7,0),(127,0),(123,0),(119,0),(124
,0),(57,0),(94,0),(121,0),(113,0),(63,0),(*** Exception: X: finite list
CallStack (from HasCallStack):
  errorX, called at src/Clash/Signal/Internal.hs:1693:57 in clash-prelude-1.8.1-72gLWAPSXgPDozrrxr9IhV:Cl
ash.Signal.Internal
```

OR we could use `simulate` and bundle the signals:

``` haskell
clashi> simulate @System (bundle . sevenSegment') [0..32]
[(63,0),(63,0),(6,0),(91,0),(79,0),(102,0),(109,0),(95,0),(7,0),(127,0),(123,0),(119,0),(124,0),(57,0),(9
4,0),(121,0),(113,0),(63,0),(6,0),(91,0),(79,0),(102,0),(109,0),(95,0),(7,0),(127,0),(123,0),(119,0),(124
,0),(57,0),(94,0),(121,0),(113,0),(63,0),(*** Exception: X: finite list
CallStack (from HasCallStack):
  errorX, called at src/Clash/Signal/Internal.hs:1693:57 in clash-prelude-1.8.1-72gLWAPSXgPDozrrxr9IhV:Cl
ash.Signal.Internal
```

The advantage to bundling the signals in the function is that we can use
`simulateN` without having to call `bundle`, which is convenient.

``` haskell
clashi> simulateN @System 32 (bundle . sevenSegment') [0..]
[(63,0),(63,0),(6,0),(91,0),(79,0),(102,0),(109,0),(95,0),(7,0),(127,0),(123,0),(119,0),(124,0),(57,0),(9
4,0),(121,0),(113,0),(63,0),(6,0),(91,0),(79,0),(102,0),(109,0),(95,0),(7,0),(127,0),(123,0),(119,0),(124
,0),(57,0),(94,0),(121,0)]
```

------

### Conclusion
