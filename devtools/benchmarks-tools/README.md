
This directory is used to run on a regular basis all the benchmarks for the Tezos protocol on the latest commit of the master branch. For motivation, see https://gitlab.com/tezos/tezos/-/milestones/143#tab-issues.


Here is the setup we chose:

- benchmarks are run on the reference machine (163.172.52.82) from a new user named "mclaren".
- we use Cron to run the benchmarks twice a week; at 8PM on tuesdays and fridays.
- for each run, the results are moved to a directory whose name indicates both the date of the (start of the) run and the head commit hash of the benchmarked Octez commit. 

Directory structure:
```
/data/tezos-benchmarks/
  - READEME.md (this file)
  - cronjob.sh
  - run_all_benchmarks_on_latest_master.sh
  - rustup-init.sh
  - snoop_results/
      - _snoop_<SOMEDATE>_<SOMECOMMITHASH>/ (one directory per run)
          - benchmark_results/
          - inference_results/
      - output_<SOMEDATE>_<SOMECOMMITHASH>.log/ (one file per run)
      - errors_<SOMEDATE>_<SOMECOMMITHASH>.log/ (one file per run)
  - tezos/
      - _snoop/
          - michelson_data/
          - sapling_data/
          - benchmark_results/ (only present during a run)
          - inference_results/ (only present during a run)
      - everything else we have in the Octez git repo
  - cron_res (only present during a run)
  - cron_res_errors (only present during a run)
``` 

Scripts:

- the user crontab can be displayed with `crontab -l`, edited with `crontab -e`
