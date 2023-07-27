Testing job selection:


  $ ./tezt.sh --file main.ml --list-tsv job_selection
  test/cram/main.ml	4s test	job_selection
  test/cram/main.ml	2s test (1)	job_selection
  test/cram/main.ml	2s test (2)	job_selection
  $ ./tezt.sh --file main.ml --list-tsv --time --from-record record-job-selection.json job_selection
  test/cram/main.ml	4s test	job_selection	4000000	1	0	0
  test/cram/main.ml	2s test (1)	job_selection	2000000	1	0	0
  test/cram/main.ml	2s test (2)	job_selection	2000000	1	0	0
  $ ./tezt.sh --file main.ml --list-tsv --time --from-record record-job-selection.json --job 1/2 job_selection
  test/cram/main.ml	4s test	job_selection	4000000	1	0	0
  $ ./tezt.sh --file main.ml --list-tsv --time --from-record record-job-selection.json --job 2/2 job_selection
  test/cram/main.ml	2s test (1)	job_selection	2000000	1	0	0
  test/cram/main.ml	2s test (2)	job_selection	2000000	1	0	0
