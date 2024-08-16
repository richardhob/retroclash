# Basics from Retrocomputing with Clash

Retro.First -> BASICs from Chapter 2

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
