Test the Cli.get_* functions.

  $ ./tezt.sh --test 'Cli.get' --info
  Starting test: Cli.get
  str_ucase: None
  int: None
  bool: None
  float: None
  [SUCCESS] (1/1) Cli.get
  $ ./tezt.sh --test 'Cli.get' --info -a str_ucase=foo -a int=99 -a bool=false -a float=3.14
  Starting test: Cli.get
  str_ucase: Some FOO
  int: Some 99
  bool: Some false
  float: Some 3.14
  [SUCCESS] (1/1) Cli.get

