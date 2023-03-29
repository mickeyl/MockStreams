# MockStreams

## Mocking streams in Swift.

This library contains implementations of a pair of `Stream` subclasses intended for helping with unit testing
code that uses `Foundation`'s `Stream` instances.

## How to use.

First, create an instance of the `MockInputStream`:

```swift
let inputStream = MockInputStream()
```

Then, create an instance of the `MockOutputStream` with the corresponding `MockInputStream` and
a dictionary of request/response pairs:

```swift

let dict: [String: String] = [
    "FOO": "BAR"
]

let outputStream = MockOutputStream(inputStream: inputStream, stringDict: dict)
```

Now, whenever you output something via the output stream, it gets forwarded as
an input to the corresponding input stream. 