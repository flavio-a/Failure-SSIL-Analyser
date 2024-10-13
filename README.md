# LIS-Project

### Dependencies
- [OCaml](https://ocaml.org/) - OCaml Version 4.14
- [OPAM](https://opam.ocaml.org/) - OCaml Package Manager
- [Dune](https://dune.build/) - build system

### Installing the dependencies
- `bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"`
- `opam init`
- `opam update`
- `opam install dune ppx_deriving odoc ppx_inline_test menhirLib sexplib menhir`
- `git submodule update --init --recursive`

### Building and running
- `make build`
- `dune exec lisproject`

### Testing
- `make test`
- `make test-rerun` To force running all the tests (even cached ones)

### Documentation
- `make doc` To only build the documentation
- `make docopen` To build and then open the documentation in browser
- The built documentation can be found at `./_build/default/_doc/_html/index.html`

### Install build
- `make install`
- The executable and the generated documentation can be found at `./_install`

### Troubleshooting
-   Dune not found after successful installation
    ```
    dune build
    make: dune: No such file or directory
    ```
    solution: `eval $(opam env)`

## Running in Docker
To build the image:
```
docker build -t ssil-failure .
```

To create the container the first time
```
docker run -it --name ssil -v $(pwd):/home/opam/Failure ssil-failure bash
```

To run it afterwards
```
docker start ssil
docker exec -it ssil bash
```

From inside the container, to run examples:
```
cd ~/Failure
opam exec -- dune exec lisproject <filename>
```

The examples in the paper can be found in the `~/Failure/examples` directory.
For instance, to run Example 5.2, use
```
opam exec -- dune exec lisproject examples/push_back.txt
```
