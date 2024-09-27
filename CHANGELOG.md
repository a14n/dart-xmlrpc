# Changelog

## 0.5.1 (2024-09-27)

- improve pub.dev score
- bump dependency versions

## 0.5.0 (2023-07-25)

- Migrate to Dart 3

## 0.4.0 (2021-03-09)

- Migrate to null safe dart
- Only Uri accepted as url parameter on client to mimic change by `package:http`. Call `Uri.parse(url)` if you previously passed in a string

## 0.3.0 (2020-05-11)

- Add server support
- Deprecate `client` param of `call` method to replace it with a `httpPost`
parameter. As only `client.post` is used it's easier to provide a custom http
handler.

## 0.2.4 (2020-01-30)

- Improve pub score.

## 0.2.3 (2020-01-27)

- Bump some dependencies.

## 0.2.2 (2018-08-01)

- Migration to Dart 2.

## 0.2.1 (2018-06-20)

- Handle `<value />` that can occur with empty strings.

## 0.2.0 (2018-06-18)

- Switch to Dart 2.
- Allow to specify the encoders/decoders used. This allows to communicate
with XML-RPC implementation that have extensions like `<nil>`, `<i8>`...
- Expose a `client_c.dart` library that directly handle `<nil>` and `<i8>`
extension types.

## 0.1.4 (2016-11-24)

- Evo: remove crypto dependency

## 0.1.3 (2015-02-05)

- Evo: allow to specify encoding for calls.

## 0.1.2 (2015-01-31)

- Evo: `call` accepts an optional named parameter `client` allowing to make the
calls from browser.
- Fix: If no type is indicated, the type is string.
- Fix: `<boolean>` instead of `<bool>`.

## 0.1.1 (2015-01-30)

- Fix: Http exception are not catched.

## 0.1.0 (2015-01-28)

- First completed version for client side usage.

# Semantic Version Conventions

http://semver.org/

- *Stable*:  All even numbered minor versions are considered API stable:
  i.e.: v1.0.x, v1.2.x, and so on.
- *Development*: All odd numbered minor versions are considered API unstable:
  i.e.: v0.9.x, v1.1.x, and so on.
