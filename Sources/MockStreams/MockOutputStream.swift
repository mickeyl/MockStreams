import Foundation

/// An ``OutputStream`` subclass for mocking purposes.
/// Register valid responses which are then sent via the corresponding ``MockInputStream``.
public final class MockOutputStream: OutputStream {

    public typealias BufferDict = [[UInt8]: [UInt8]]

    /// The registered responses.
    private var bufferDict: BufferDict = .init()
    /// The writing buffer.
    private var buffer: [UInt8] = []
    /// The corresponding mock input stream.
    private let inputStream: MockInputStream
    /// The delegate.
    private var delegat: StreamDelegate? = nil
    /// The run loop.
    private var runloop: RunLoop? = nil
    /// The stream status.
    private var status: Stream.Status = .notOpen
    /// The stream error.
    private var error: Error? = nil

    public init(inputStream: MockInputStream, bufferDict: BufferDict) {
        self.inputStream = inputStream
        self.bufferDict = bufferDict
        super.init(toMemory: ())
    }

    public convenience init(inputStream: MockInputStream, stringDict: [String: String]) {
        var bufferDict: BufferDict = .init()
        for (key, value) in stringDict {
            let binKey: [UInt8] = Array(key.utf8)
            let binValue: [UInt8] = Array(value.utf8)
            bufferDict[binKey] = binValue
        }
        self.init(inputStream: inputStream, bufferDict: bufferDict)
    }
}

//MARK: - OutputStream
public extension MockOutputStream {

    override var streamStatus: Stream.Status { self.status }
    override var hasSpaceAvailable: Bool { true }
    override var delegate: StreamDelegate? {
        set { self.delegat = newValue }
        get { self.delegat }
    }
    override var streamError: Error? {
        set { self.error = newValue }
        get { self.error }
    }

    override func open() {
        guard self.streamStatus == .notOpen else { return }
        self.status = .opening
        self.status = .open
        self.notifyDelegate(.openCompleted)
        self.notifyDelegate(.hasSpaceAvailable)
    }

    override func write(_ buffer: UnsafePointer<UInt8>, maxLength len: Int) -> Int {
        let pointer = UnsafeBufferPointer(start: buffer, count: len)
        self.buffer.append(contentsOf: pointer)
        defer { self.inspectBuffer() }
        return len
    }

    override func close() {
        guard self.streamStatus == .open else { return }
        self.status = .closed
        self.notifyDelegate(.endEncountered)
    }

    override func schedule(in aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.runloop = aRunLoop
    }

    override func remove(from aRunLoop: RunLoop, forMode mode: RunLoop.Mode) {
        self.runloop = nil
    }
}

//MARK: - Helpers
private extension MockOutputStream {

    func inspectBuffer() {

        while !self.buffer.isEmpty {

            for pduLength in 1...self.buffer.count {
                let partialBuffer = Array(self.buffer[0..<pduLength])
                guard let response = self.bufferDict[partialBuffer] else { continue }
                defer { self.inputStream.feed(response) }
                self.buffer.removeFirst(pduLength)
                break
            }
            break
        }
    }

    func notifyDelegate(_ event: Stream.Event) {
        guard let delegate = self.delegate, let runloop = self.runloop else { return }
        runloop.perform {
#if canImport(ObjectiveC)
            delegate.stream?(self, handle: event)
#else
            delegate.stream(self, handle: event)
#endif
        }
    }
}
