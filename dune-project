(lang dune 3.14)

(name lisproject)

(generate_opam_files true)

(source
 (uri https://github.com/anonymous))

(authors
  "Anonymous Author"
)

(using menhir 3.0)

(license GPL-3.0-or-later)

(package
 (name lisproject)
 (depends ocaml dune)
)
