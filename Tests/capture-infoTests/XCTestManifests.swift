import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(capture_infoTests.allTests),
    ]
}
#endif