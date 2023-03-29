import Foundation

/// An ``InputStream`` subclass for mocking purposes.
/// Append bytes you want the stream to deliver via ``feed(_:)``.
public final class MockInputStream: InputStream {

    /// The reading buffer.
    private var buffer: [UInt8] = []
    /// The run loop.
    private var runloop: RunLoop? = nil
    /// The delegate.
    private var delegat: StreamDelegate? = nil
    /// The stream status.
    private var status: Stream.Status = .notOpen
    /// The stream error.
    private var error: Error? = nil

    public init() {
        super.init(data: .init())
    }

    /// Feeds more bytes.
    public func feed(_ bytes: [UInt8]) {
        let bufferWasEmpty = self.buffer.isEmpty
        self.buffer += bytes
        if bufferWasEmpty {
            self.notifyDelegate(.hasBytesAvailable)
        }
    }
}

//MARK: - InputStream
public extension MockInputStream {

    override var streamStatus: Stream.Status { self.status }
    override var hasBytesAvailable: Bool { !self.buffer.isEmpty }
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

        guard self.hasBytesAvailable else { return }
        self.notifyDelegate(.hasBytesAvailable)
    }

    override func read(_ buffer: UnsafeMutablePointer<UInt8>, maxLength len: Int) -> Int {
        let nRead = min(len, self.buffer.count)
        let rawBuffer = UnsafeMutableRawBufferPointer(start: buffer, count: nRead)
        self.buffer.copyBytes(to: rawBuffer)
        self.buffer.removeFirst(nRead)
        return nRead
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
private extension MockInputStream {

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
