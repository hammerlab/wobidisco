Building Complex Biokepi Input.t Values
=======================================

Pipelines like Epidisco can take their inputs by parsing their command line, if
you have simple inputs it is usually enough.

See the help section related to inputs in Epidisco:


```
SAMPLES
       The sample data (tumor DNA, normal DNA, and, optionally, tumor RNA) to
       be passed into the pipeline.

       Use a comma (,) as a delimiter to provide multiple data files and an
       ampersand (@) when describing paired-end FASTQ files.

       Examples
       - JSON file: file://path/to/sample.json
       - BAM file: https://url.to/my.bam
       - Single-end FASTQ: /path/to/single.fastq.gz,..
       - Paired-end FASTQ: /p/t/pair1.fastq@/p/t/pair2.fastq,..

       Each comma-separated BAM or FASTQ (paired or single-ended) will be
       treated as an individual sample before being merged into the single
       tumor/normal/RNA sample the rest of the pipeline deals with.

       --normal-inputs=VAR,... (required)
           Normal sample(s) for the pipeline.

       --rna-inputs=VAR,...
           RNA sample(s) for the pipeline.

       --tumor-inputs=VAR,... (required)
           Tumor sample(s) for the pipeline.
```

The DSL with `,` and `@` is quite expressive but still not enough, for example
we cannot input various Bams or FASTQ pairs as “fragments” of a same sample
(e.g. when your sequencing core hands you split and numbered FASTQ files, or
when you want to treat different sequencer *lanes* as the same semantic sample).
Moreover, even when use cases can be expressed, those long command lines are
hard to read and difficult to update.

Hopefully, inputs can be described in a JSON file, which themselves can be
generated from a real programming language.

See for instance this `normal_01.ml`:

```ocaml
#use "topfind";;
#thread;;
#require "biokepi";;

(*
  Defining a single sample with 2 “fragments” which are paired-end FASTQ files.
*)
let normal_inputs =
  let open Biokepi_pipeline_edsl.Pipeline_library.Input in
  fastq_sample ~sample_name:"My-patient-04-normal" [
    pe ~fragment_id:"L1"
      "/data/patient-04/PR42_001_PB_DNA_S1_L001_R1_001.fastq.gz"
      "/data/patient-04/PR42_001_PB_DNA_S1_L001_R2_001.fastq.gz";
    pe ~fragment_id:"L2"
      "/data/patient-04/PR42_001_PB_DNA_S1_L002_R1_001.fastq.gz"
      "/data/patient-04/PR42_001_PB_DNA_S1_L002_R2_001.fastq.gz";
]
(*
  Outputting the sample to `stdout`  in JSON format.
*)
let () =
  Biokepi_pipeline_edsl.Pipeline_library.Input.to_yojson normal_inputs
  |> Yojson.Safe.pretty_to_channel stdout
```

Will output a nice example of JSON input (if by some chance one wants to write
this manually):

```
{
  "biokepi-input-v0": {
    "fastq": {
      "sample-name": "My-patient-04-normal",
      "fragments": [
        {
          "fragment-id": "L1",
          "data": {
            "paired-end": {
              "r1":
                "/data/patient-04/PR42_001_PB_DNA_S1_L001_R1_001.fastq.gz",
              "r2":
                "/data/patient-04/PR42_001_PB_DNA_S1_L001_R2_001.fastq.gz"
            }
          }
        },
        {
          "fragment-id": "L2",
          "data": {
            "paired-end": {
              "r1":
                "/data/patient-04/PR42_001_PB_DNA_S1_L002_R1_001.fastq.gz",
              "r2":
                "/data/patient-04/PR42_001_PB_DNA_S1_L002_R2_001.fastq.gz"
            }
          }
        }
      ]
    }
  }
```

Those scripts can of course become arbitrarily complex and embrace the user's
data management assumptions and choices, e.g.:

```ocaml
(** 
   This script generates Input.t descriptions for file trees of the form:
   {v
     patient-<nb>/
       \-> normal/
          \-> <flowcell-id>-<lane>-<read-nb>.fastq.gz
          \-> ...
       \-> tumor/
          \-> <flowcell-id>-<lane>-<read-nb>.fastq.gz
          \-> ...
       \-> rna/
          \-> <flowcell-id>-<lane>-<read-nb>.fastq.gz
          \-> ...
   v}
   
   Those file structures can be in a Google-Cloud bucket
   ["gs://my-google-bucket"] or locally at ["/data/cached/"].

 *)
#use "topfind";;
#thread;;
#require "biokepi";;
open Printf
module List = ListLabels

(**
  val from : storage:[ `Local | `My_gbucket ] -> string -> string = <fun>
  Build paths.
*)
let from ~storage basename =
  match storage with
  | `My_gbucket -> sprintf "gs://my-google-bucket/patient-04/%s" basename
  | `Local -> sprintf "/data/cached/patient-04/%s" basename

(**
   val sample :
      storage:[ `Local | `My_gbucket ] ->
      [ `Normal | `Rna | `Tumor ] ->
      'a list -> Biokepi_pipeline_edsl.Pipeline_library.Input.t = <fun>
*)
let sample ~storage kind lanes =
  let open Biokepi_pipeline_edsl.Pipeline_library.Input in
  let kind_str =
    match kind with
    | `Normal -> "normal"
    | `Tumor -> "tumor"
    | `Rna -> "rna" in
  fastq_sample ~sample_name:(sprintf "My-patient-04-%s" kind_str)
    (List.mapi lanes ~f:(fun number base ->
         let lane = number + 1 in
         pe ~fragment_id:(sprintf "L%d" lane)
           (from ~storage (sprintf "%s/%s-R1.fastq.gz" kind_str base))
           (from ~storage (sprintf "%s/%s-R2.fastq.gz" kind_str base))))


let normal = ["DCX42CXX_L001"; "DCX42CXX_L002"; "AGX51CXX_L001"]
let tumor  = ["DCX42CXX_L003"; "DCX42CXX_L004"; "AGX51CXX_L002"]
let rna    = ["DCX42CXX_L005"; "DCX42CXX_L005"; "AGX51CXX_L003"]

(*
  Outputting the samples to `stdout` in JSON format.
*)
let () =
  if Array.length Sys.argv < 3 then (
    printf "usage: %s {gbucket,local} {normal,tumor,rna}\n%!" Sys.argv.(0);
    exit 1
  );
  let storage =
    match Sys.argv.(1) with
    | "gbucket" -> `My_gbucket
    | "local" -> `Local
    | other -> failwith (sprintf "Can't undestand %S for storage" other)
  in
  let sample =
    match Sys.argv.(2) with
    | "normal" -> sample ~storage `Normal normal
    | "tumor" -> sample ~storage `Tumor tumor
    | "rna" -> sample ~storage `Rna rna
    | other -> failwith (sprintf "Can't undestand %S for the sample" other)
  in
  Biokepi_pipeline_edsl.Pipeline_library.Input.to_yojson sample
  |> Yojson.Safe.pretty_to_channel stdout
```

And an example output:

```
 $ ocaml test-sample.ml
usage: test-sample.ml {gbucket,local} {normal,tumor,rna}
 $ ocaml test-sample.ml gbucket tumor
{
  "biokepi-input-v0": {
    "fastq": {
      "sample-name": "My-patient-04-tumor",
      "fragments": [
        {
          "fragment-id": "L1",
          "data": {
            "paired-end": {
              "r1":
                "gs://my-google-bucket/patient-04/tumor/DCX42CXX_L003-R1.fastq.gz",
              "r2":
                "gs://my-google-bucket/patient-04/tumor/DCX42CXX_L003-R2.fastq.gz"
            }
          }
        },
        {
          "fragment-id": "L2",
          "data": {
            "paired-end": {
              "r1":
                "gs://my-google-bucket/patient-04/tumor/DCX42CXX_L004-R1.fastq.gz",
              "r2":
                "gs://my-google-bucket/patient-04/tumor/DCX42CXX_L004-R2.fastq.gz"
            }
          }
        },
        {
          "fragment-id": "L3",
          "data": {
            "paired-end": {
              "r1":
                "gs://my-google-bucket/patient-04/tumor/AGX51CXX_L002-R1.fastq.gz",
              "r2":
                "gs://my-google-bucket/patient-04/tumor/AGX51CXX_L002-R2.fastq.gz"
            }
          }
        }
      ]
    }
  }
}
```

See also the documentation of the module
[`Biokepi_pipeline_edsl.Pipeline_library.Input`](http://www.hammerlab.org/docs/biokepi/master/api/Biokepi_pipeline_edsl.Pipeline_library.Input.html).

