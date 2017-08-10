Wobidisco
=========

Workflows Bioinformatics and Discoballs: The Biokepiverse.

This is the umbrella documentation/tooling project for:

- [Biokepi](https://github.com/hammerlab/biokepi): a library of composable
  “pieces of bioinformatics workflows” (a.k.a. *“nodes”*).
- [Ketrew](https://github.com/hammerlab/ketrew): a computational workflow
  manager on which Biokepi is based.
- [Coclobas](https://github.com/hammerlab/coclobas): Ketrew can interact with
  Torque/PBS, Platform LSF, YARN, and other HPC schedulers; Coclobas is another
  such scheduler, specialized in cloud/docker computing environments (Google
  Container Engine, AWS Batch, or “local” Docker).
- [Epidisco](https://github.com/hammerlab/epidisco): a Biokepi workflow used in
  production for a clinical trial; i.e. an actively maintained large workflow
  example.
- [Secotrec](https://github.com/hammerlab/secotrec): a deployment/administration
  tool for Ketrew/Coclobas setups.


Documentation
-------------

Individual projects have detailed documentation websites at
<http://hammerlab.org/docs>.

The following tutorials are available here:

- [Running](./doc/running-local.md) Epidisco (or any Biokepi workflow) using
  Ketrew/Coclobas in *local-docker* mode (i.e. using Coclobas to schedule docker
  containers on a single machine).
  


