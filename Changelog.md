# Changelog

## Master

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
