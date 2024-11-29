# Changelog

## 0.10.1
- Use `as_json` to ensure scheduling jobs is compatible with Sidekiq strict args

## 0.10.0
- Make scheduling jobs compatible with Sidekiq strict args

## 0.9.1
- Improve handling database connections when the server kills the connection

## 0.9.0
- Handle database reconnection for distributed traces as it might cause some issues with RPCs/synchronous flows

## 0.8.0

- Fix `database_connection_provider` config option: avoid calling connection on app initialization

## 0.7.5

- Make `Hermes::Logger::ParamsFilter` correctly handle regexps

## 0.7.4

- Make `Hermes::Logger::ParamsFilter` handle case-insensitive matches

## 0.7.3

- Handle database reconnection in synchronous flow
- Improve test coverage of `Hermes::Logger::ParamsFilter` - cover regular expressions

## 0.7.2
- Clear Hermes.origin_headers after calling event handlers

## 0.7.1
- Fix Hermes::DistributedTraceRepository so that it properly applies mapper that modifies event body

## 0.7.0
- Add support for DDTrace v1

## 0.6.1
- Extend the list of sensitive keywords for Hermes::Logger::ParamsFilter

## 0.6.0
- Add Health check

## 0.5.0
- Add Datadog tracer
- Allow to provide a custom tracer

## 0.4.0
- Make it possible to provide Hutch consumer config

## 0.3.1
- Fix filtering params for logs for nil values in sensitive attributes

## 0.3.0
- Reorganize Hutch config - instead of setting config values when connecting to Hutch when using publisher, do it right after the initialization.
- Make params filter customizable for the logger
- Remove sensitive info when creating distributed trace records.

## 0.2.0
- Implement "Safe Producer" extension allowing to retry delivery later in an automated way when publishing of the message fails.

## 0.1.0
- Initial release
