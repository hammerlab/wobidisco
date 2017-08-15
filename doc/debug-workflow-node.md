Create a Debug Workflow Node
============================

We went to create a “debug” workflow node with the same environment as any other
Biokepi node and connect to it to be able to experiment/troubleshoot commands.

When Secotrec/Ketrew/OCaml Are Available
----------------------------------------

See one of the commands (depending on your setup):

    secotrec-local deploy-debug-node --help
    secotrec-gke deploy-debug-node --help
    secotrec-aws deploy-debug-node --help

For the GKE setup see the screenshot in the
PR [`hammerlab/secotrec#74`](https://github.com/hammerlab/secotrec/pull/74).

While “Running-Local”
---------------------

For the setup as in the “running-local” [tutorial](./doc/running-local.md), the
above commands do not work because `secotrec-local` is fetched without its
corresponding `opam`/`ketrew` environment:

    secotrec-local deploy-debug-node

gives

```
/tmp/run-genspiof73f45-cmd.sh: line 5: ketrew: command not found
sh: 1: ocaml: not found
```

So, let's configure the “launch environment” as in the tutorial:

    secotrec-local biokepi-machine $epidisco_dev/biokepi_machine.ml
    secotrec-local docker-compose -- exec epidisco-dev opam config exec bash
    ketrew init --just-client http://kserver:8080/gui?token=dsleaijdej308098ddecja9c8jra8cjrf98r


And use this workflow script instead (cf. also
this [gist](https://gist.github.com/731e8cc0ee61e09ff02d3723f5e388e8)):

    curl -L -o debug-workflow.ml \
      https://gist.github.com/smondet/731e8cc0ee61e09ff02d3723f5e388e8/raw/19a9641a1d22d473d8bca41ca1745abf9f29429a/wobi-local-deploy-debug.ml

And start the workflow:

    ocaml debug-workflow.ml

Grab the ID of the container from the Ketrew UI:

<div><a href="https://user-images.githubusercontent.com/617111/29187914-58bdcbbe-7ddf-11e7-88ce-9c5581a4b624.gif"><img
 width="80%"
  src="https://user-images.githubusercontent.com/617111/29187914-58bdcbbe-7ddf-11e7-88ce-9c5581a4b624.gif"
></a></div>

Or using the TextUI from inside the container:

<div><a href="https://user-images.githubusercontent.com/617111/29188917-b2a49fa6-7de2-11e7-9e37-d613abe00c83.gif"><img
 width="80%"
  src="https://user-images.githubusercontent.com/617111/29188917-b2a49fa6-7de2-11e7-9e37-d613abe00c83.gif"
></a></div>

Then you need to `exit` the *launch-countainer*:

    exit

you can now use the container ID to “join” the workflow-node:

    docker exec -it 'f0fe431d-4874-5220-bbbe-8e789ea8bd67' bash

And you are now in a container, see:

```
 $ whoami
biokepi
 $ java -version
java version "1.8.0_131"
Java(TM) SE Runtime Environment (build 1.8.0_131-b11)
Java HotSpot(TM) 64-Bit Server VM (build 25.131-b11, mixed mode)
```
