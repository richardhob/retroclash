# Working with Clash Lang

- [Install](https://clash-lang.org/install/linux/)
- [Prelude Package (Hackage)](https://hackage.haskell.org/package/clash-prelude-1.8.1)
- [Tutorial (Hackage)](https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Tutorial.html)
- [Github](https://github.com/clash-lang/clash-compiler)

## Tutorial

To create the tutorial:

``` bash
stack new my-clash-project clash-lang/simple
```

The "README.md" contains a bunch more information on using the project / using
stack.

See: 

- [Default README](tutorial01/README.md)

## Quick Reference

- `stack build`
- `stack test`
- `stack run clash -- Example.Project --vhdl`
- `stack run clashi`
