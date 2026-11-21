<img align="left" width="72" src="https://codeberg.org/kitty/gsable/raw/commit/dadd226e3ad178a71966e22b0b9ada161b8dce2d/assets/icon.png">

# sable

**sable** is a [concatenative][3] programming language with dynamic types and [arrays][4] like [APL][5]. Work in progress!!

## Installation

Ensure the following dependencies are installed on your machine:

- [zig][1] (v0.17.x)
- [SDL3][2]

Then, build the project from source.

```sh
$ git clone https://codeberg.org/kitty/sable
$ cd sable
$ zig build install --prefix=~/.local --release=fast
```

## Usage
The `sbl` binary can be used to run programs or an interactive REPL (read-eval-print-loop).

```sh
$ sbl --help
usage: sbl [options] [input-file...]

   -h, --help         Print this help message and exit.
   -v, --version      Print the version number and exit.
   -r, --repl         Run the sable repl.
   --verbose-ast      Dumps the parsed ast tree to stderr.
   --verbose-bc       Dumps the compiled bytecode to stderr.
```

## Interpreter Limitations

- Source files must be UTF-8 encoded, and cannot be greater than 4.2GB in size
- The interpreter cannot open more than 256 files at once
- Tokens may not be larger than 512 bytes

## License

This project is licensed under AGPLv3. For details, see the [LICENSE](LICENSE) file included in this repository.

[1]: https://ziglang.org
[2]: https://wiki.libsdl.org/SDL3/FrontPage
[3]: https://en.wikipedia.org/wiki/Concatenative_programming_language
[4]: https://aplwiki.com/wiki/Array
[5]: https://aplwiki.com/wiki/APL
