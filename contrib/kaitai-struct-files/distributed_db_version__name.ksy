meta:
  id: distributed_db_version__name
  endian: be
doc: A name for the distributed DB protocol
seq:
- id: size_of_distributed_db_version__name
  type: s4
- id: distributed_db_version__name
  size: size_of_distributed_db_version__name
