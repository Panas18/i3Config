(block_mapping_pair
  key: (flow_node) @_run
  (#any-of? @_run "queryText")
  value: (flow_node
    (plain_scalar
      (string_scalar) @injection.content)
    (#set! injection.language "xml")))
