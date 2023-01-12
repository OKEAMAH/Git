Run benchmark to dump json data later
  $ ./main_snoop.exe benchmark proto/alpha/interpreter/N_IBlake2b and save to data.workload --bench-num 2 --nsamples 3  2>&1 | grep -v benchmarking|sed s'/stats over all benchmarks:.*/stats <hidden>/'
  Model N_IOpt_map__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Model N_ILambda__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Model N_ISapling_verify_update__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Model N_ISapling_verify_update__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Model N_ISapling_verify_update__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Model N_KIter__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Model N_KList_enter_body__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Model N_KMap_enter_body__alpha already registered for code generation! (overloaded instruction?) Ignoring.
  Benchmarking with the following options:
  { options = { seed=self-init;
                bench #=2;
                nsamples/bench=3;
                minor_heap_size=262144 words;
                config directory=None };
     save_file = data.workload;
     storage = Mem }
  Using default configuration for benchmark proto/alpha/interpreter/N_IBlake2b
  { "sampler":
      { "int_size": { "min": 8, "max": 100000 },
        "string_size": { "min": 1024, "max": 131072 },
        "bytes_size": { "min": 1024, "max": 131072 },
        "list_size": { "min": 10, "max": 1000 },
        "set_size": { "min": 10, "max": 1000 },
        "map_size": { "min": 10, "max": 1000 } },
    "sapling": { "sapling_txs_file": "/no/such/file", "seed": null },
    "comb": { "max_depth": 1000 },
    "compare": { "type_size": { "min": 1, "max": 15 } } }
  stats <hidden>

Dump workload json to file
  $ ./main_snoop.exe workload dump data.workload to data.json 2>&1 |grep -v "already registered for code"
  Measure.load: loaded data.workload
  Measure.packed_measurement_save_json: saved to data.json

Echo data.json file.
  $ cat data.json | jq  '(.measurement_data.date |= "DATE") | (.measurement_data.workload_data |= map((.measures |= map("TIME")) | (.workload[0][1][0][1] |= "SIZE")))'
  {
    "benchmark_namespace": [
      "proto",
      "alpha",
      "interpreter",
      "N_IBlake2b"
    ],
    "measurement_data": {
      "benchmark_options": {
        "seed": null,
        "samples_per_bench": "3",
        "bench_number": "2",
        "minor_heap_size": "262144",
        "config_file": null
      },
      "workload_data": [
        {
          "workload": [
            [
              "N_IBlake2b",
              [
                [
                  "bytes",
                  "SIZE"
                ]
              ]
            ],
            [
              "N_IHalt",
              []
            ]
          ],
          "measures": [
            "TIME",
            "TIME",
            "TIME"
          ]
        },
        {
          "workload": [
            [
              "N_IBlake2b",
              [
                [
                  "bytes",
                  "SIZE"
                ]
              ]
            ],
            [
              "N_IHalt",
              []
            ]
          ],
          "measures": [
            "TIME",
            "TIME",
            "TIME"
          ]
        }
      ],
      "date": "DATE"
    }
  }
