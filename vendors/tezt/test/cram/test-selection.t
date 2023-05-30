Test the '--file' filter.

  $ ./tezt.sh selection --list
  +----------+----------+-----------+
  |   FILE   |  TITLE   |   TAGS    |
  +----------+----------+-----------+
  | a/b/c.ml | a/b/c.ml | selection |
  | a/b/g.ml | a/b/g.ml | selection |
  | a/c.ml   | a/c.ml   | selection |
  | d.ml     | d.ml     | selection |
  | e.ml     | e.ml     | selection |
  +----------+----------+-----------+

  $ ./tezt.sh selection --file 'a/b/c.ml' --list
  +----------+----------+-----------+
  |   FILE   |  TITLE   |   TAGS    |
  +----------+----------+-----------+
  | a/b/c.ml | a/b/c.ml | selection |
  +----------+----------+-----------+
  $ ./tezt.sh selection --file 'c.ml' --list
  +----------+----------+-----------+
  |   FILE   |  TITLE   |   TAGS    |
  +----------+----------+-----------+
  | a/b/c.ml | a/b/c.ml | selection |
  | a/c.ml   | a/c.ml   | selection |
  +----------+----------+-----------+
  $ ./tezt.sh selection --file 'b/c.ml' --list
  +----------+----------+-----------+
  |   FILE   |  TITLE   |   TAGS    |
  +----------+----------+-----------+
  | a/b/c.ml | a/b/c.ml | selection |
  +----------+----------+-----------+
  $ ./tezt.sh selection --file 'a/c.ml' --list
  +--------+--------+-----------+
  |  FILE  | TITLE  |   TAGS    |
  +--------+--------+-----------+
  | a/c.ml | a/c.ml | selection |
  +--------+--------+-----------+
  $ ./tezt.sh selection --file 'd.ml' --list
  +------+-------+-----------+
  | FILE | TITLE |   TAGS    |
  +------+-------+-----------+
  | d.ml | d.ml  | selection |
  +------+-------+-----------+
  $ ./tezt.sh selection --file '' --list
  [warn] Unknown file or file suffix: 
  No test found for filters: --file  selection
  [3]
  $ ./tezt.sh selection --file '.ml' --list
  [warn] Unknown file or file suffix: .ml
  No test found for filters: --file .ml selection
  [3]
  $ ./tezt.sh selection --file 'c.ml' --file 'd.ml' --list
  +----------+----------+-----------+
  |   FILE   |  TITLE   |   TAGS    |
  +----------+----------+-----------+
  | a/b/c.ml | a/b/c.ml | selection |
  | a/c.ml   | a/c.ml   | selection |
  | d.ml     | d.ml     | selection |
  +----------+----------+-----------+
  $ ./tezt.sh selection --not-file 'c.ml' --list
  +----------+----------+-----------+
  |   FILE   |  TITLE   |   TAGS    |
  +----------+----------+-----------+
  | a/b/g.ml | a/b/g.ml | selection |
  | d.ml     | d.ml     | selection |
  | e.ml     | e.ml     | selection |
  +----------+----------+-----------+
  $ ./tezt.sh selection --not-file 'b/g.ml' --list
  +----------+----------+-----------+
  |   FILE   |  TITLE   |   TAGS    |
  +----------+----------+-----------+
  | a/b/c.ml | a/b/c.ml | selection |
  | a/c.ml   | a/c.ml   | selection |
  | d.ml     | d.ml     | selection |
  | e.ml     | e.ml     | selection |
  +----------+----------+-----------+
  $ ./tezt.sh selection --file 'c.ml' --not-file 'b/c.ml' --list
  +--------+--------+-----------+
  |  FILE  | TITLE  |   TAGS    |
  +--------+--------+-----------+
  | a/c.ml | a/c.ml | selection |
  +--------+--------+-----------+
