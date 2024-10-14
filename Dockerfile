FROM ocaml/opam:opensuse-ocaml-5.2

# Install libs
RUN opam init --reinit -ni
RUN opam update
RUN opam install dune ppx_deriving odoc ppx_inline_test menhirLib sexplib menhir

# Our stuff
WORKDIR /home/opam/Failure
COPY . .
RUN opam exec -- make build

CMD ["bash"]
