#if !os(WASI)
import Dispatch
#endif

/// Make an ``AsyncExpectation`` on a given actual value. The value given is lazily evaluated.
public func expect<T: Sendable>(file: FileString = #file, line: UInt = #line, _ expression: @escaping @Sendable () async throws -> T?) -> AsyncExpectation<T> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression,
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

/// Make an ``AsyncExpectation`` on a given actual value. The closure is lazily invoked.
public func expect<T: Sendable>(file: FileString = #file, line: UInt = #line, _ expression: @Sendable () -> (@Sendable () async throws -> T)) -> AsyncExpectation<T> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression(),
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

/// Make an ``AsyncExpectation`` on a given actual value. The closure is lazily invoked.
public func expect<T: Sendable>(file: FileString = #file, line: UInt = #line, _ expression: @Sendable () -> (@Sendable () async throws -> T?)) -> AsyncExpectation<T> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression(),
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

/// Make an ``AsyncExpectation`` on a given actual value. The closure is lazily invoked.
public func expect(file: FileString = #file, line: UInt = #line, _ expression: @Sendable () -> (@Sendable () async throws -> Void)) -> AsyncExpectation<Void> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression(),
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

/// Make an ``AsyncExpectation`` on a given actual value. The value given is lazily evaluated.
/// This is provided to avoid  confusion between `expect -> SyncExpectation` and `expect -> AsyncExpectation`.
public func expecta<T: Sendable>(file: FileString = #file, line: UInt = #line, _ expression: @autoclosure @escaping @Sendable () async throws -> T?) async -> AsyncExpectation<T> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression,
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

/// Make an ``AsyncExpectation`` on a given actual value. The closure is lazily invoked.
/// This is provided to avoid  confusion between `expect -> SyncExpectation`  and `expect -> AsyncExpectation`
public func expecta<T: Sendable>(file: FileString = #file, line: UInt = #line, _ expression: @autoclosure @Sendable () -> (@Sendable () async throws -> T)) async -> AsyncExpectation<T> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression(),
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

/// Make an ``AsyncExpectation`` on a given actual value. The closure is lazily invoked.
/// This is provided to avoid  confusion between `expect -> SyncExpectation`  and `expect -> AsyncExpectation`
public func expecta<T: Sendable>(file: FileString = #file, line: UInt = #line, _ expression: @autoclosure @Sendable () -> (@Sendable () async throws -> T?)) async -> AsyncExpectation<T> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression(),
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

/// Make an ``AsyncExpectation`` on a given actual value. The closure is lazily invoked.
/// This is provided to avoid  confusion between `expect -> SyncExpectation`  and `expect -> AsyncExpectation`
public func expecta(file: FileString = #file, line: UInt = #line, _ expression: @autoclosure @Sendable () -> (@Sendable () async throws -> Void)) async -> AsyncExpectation<Void> {
    return AsyncExpectation(
        expression: AsyncExpression(
            expression: expression(),
            location: SourceLocation(file: file, line: line),
            isClosure: true))
}

#if !os(WASI)

/// Wait asynchronously until the done closure is called or the timeout has been reached.
///
/// @discussion
/// Call the done() closure to indicate the waiting has completed.
///
/// @warning
/// Unlike the synchronous version of this call, this does not support catching Objective-C exceptions.
public func waitUntil(timeout: NimbleTimeInterval = PollingDefaults.timeout, file: FileString = #file, line: UInt = #line, action: @escaping @Sendable (@escaping @Sendable () -> Void) async -> Void) async {
    await throwableUntil(timeout: timeout, sourceLocation: SourceLocation(file: file, line: line)) { done in
        await action(done)
    }
}

/// Wait asynchronously until the done closure is called or the timeout has been reached.
///
/// @discussion
/// Call the done() closure to indicate the waiting has completed.
///
/// @warning
/// Unlike the synchronous version of this call, this does not support catching Objective-C exceptions.
public func waitUntil(timeout: NimbleTimeInterval = PollingDefaults.timeout, file: FileString = #file, line: UInt = #line, action: @escaping @Sendable (@escaping @Sendable () -> Void) -> Void) async {
    await throwableUntil(timeout: timeout, sourceLocation: SourceLocation(file: file, line: line)) { done in
        action(done)
    }
}

private enum ErrorResult {
    case error(Error)
    case none
}

private func throwableUntil(
    timeout: NimbleTimeInterval,
    sourceLocation: SourceLocation,
    action: @escaping @Sendable (@escaping @Sendable () -> Void) async throws -> Void) async {
        let leeway = timeout.divided
        let result = await performBlock(
            timeoutInterval: timeout,
            leeway: leeway,
            sourceLocation: sourceLocation) { @MainActor (done: @escaping @Sendable (ErrorResult) -> Void) async throws -> Void in
                do {
                    try await action {
                        done(.none)
                    }
                } catch let e {
                    done(.error(e))
                }
            }

        switch result {
        case .incomplete: internalError("Reached .incomplete state for waitUntil(...).")
        case .blockedRunLoop:
            fail(blockedRunLoopErrorMessageFor("-waitUntil()", leeway: leeway),
                 file: sourceLocation.file, line: sourceLocation.line)
        case .timedOut:
            fail("Waited more than \(timeout.description)", file: sourceLocation.file, line: sourceLocation.line)
        case let .errorThrown(error):
            fail("Unexpected error thrown: \(error)")
        case .completed(.error(let error)):
            fail("Unexpected error thrown: \(error)")
        case .completed(.none): // success
            break
        }
}

#endif // #if !os(WASI)
