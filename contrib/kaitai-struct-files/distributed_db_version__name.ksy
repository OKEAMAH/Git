meta:
  id: distributed_db_version__name
  endian: be
doc: ! >-
  Encoding id: distributed_db_version.name

  Description: A name for the distributed DB protocol
seq:
- id: size_of_distributed_db_version__name
  type: u4
  valid:
    max: 1073741823
- id: distributed_db_version__name
  size: size_of_distributed_db_version__name
