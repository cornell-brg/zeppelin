# Zeppelin

BRG’s Superscalar Modular Processor developed by Parker Schless

## Documentation

The main documentation for Zeppelin can be found on the [GitHub Pages](https://cornell-brg.github.io/zeppelin/)

## History

Zeppelin owes much of its infrastructure and early exploratory work to
[BLIMP](https://github.com/cornell-brg/blimp), BRG's first modular processor
developed by Aidan McNay. Zeppelin would not be possible without the groundwork
laid out by BLIMP.

## Testing

Zeppelin uses CMake as its build system generator. To begin testing, first
generate the build system using CMake, optionally specifying either `Verilator`
or `VCS` as the Verilog compiler (Zeppelin uses Verilator by default)

```bash
mkdir build
cd build
cmake .. -DCMAKE_Verilog_COMPILER_ID=Verilator
```

From there, users can run any individual test by specifying its name as a
target:

```bash
make Zeppelin_add_test
```

Known tests can be listed with the `list` target.

```bash
make list
```

Finally, all tests can be run with the `check` target

```bash
make check
```

Running tests as shown above can often be slow; users may additionally want to
specify a level of parallelism (ex. `make -j ALU_test`) or specify a different
backend when generating the build system (ex. `cmake .. -GNinja`)

## Simulation

Simulation programs are kept in the `app` directory. A given program can be
built natively by with the target `app-<program>-native`, which will build
`<program>-native` in the `app` directory

```bash
make app-hello-native
./app/hello-native
```

Programs can also be built for RISCV by omitting the `native` suffix

```bash
make app-hello
```

These can then be run using the functional-level simulator, specifying
the path to the ELF file

```bash
make fl-sim
./fl-sim app/hello
```

They can also be run on Zeppelin version by making the simulator

```bash
make zeppelin-sim
./zeppelin-sim +elf=app/hello
```
