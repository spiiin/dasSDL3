# Deferred scopes (current)

See [error-handling.md](error-handling.md). Native protected owner/invoke exports
and their catch/rethrow implementations were removed. Ownership now uses script
daslib/defer with SDL errors returned as values. The former scope benchmark
relied on removed command plans and has also been removed.
