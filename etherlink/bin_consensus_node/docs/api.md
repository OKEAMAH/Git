# Public API

The consensus node exposed public gRPC endpoint for broadcasting transactions and subscribing to pre-blocks.  
It is intended to be used by a local sequencer node, effectively providing "ordering-as-a-service".
Therefore there is no authentication mechanism, make sure this endpoint is not available to everyone.
