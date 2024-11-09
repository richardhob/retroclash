
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

#include "VSevenSegment.h"

#include "verilated.h"
#include "verilated_vcd_c.h"

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


void reset(VSevenSegment* tb, VerilatedVcdC* trace);
void tick(VSevenSegment* tb, VerilatedVcdC* trace);

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

/* Reset the AXI Slave */
void reset(VSevenSegment* tb, VerilatedVcdC* trace)
{
    tb->RST = 1;

    tick(tb, trace);
    tick(tb, trace);

    tb->RST = 0;
}

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

// EOF
