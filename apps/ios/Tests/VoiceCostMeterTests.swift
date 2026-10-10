import XCTest
@testable import MuralCore

final class VoiceCostMeterTests: XCTestCase {
    func testUnconnectedAndFailedBeforeCreationHaveNoCharge() {
        var meter = VoiceCostMeter()
        meter.finish(now: 200)
        XCTAssertNil(meter.estimatedUSD(now: 500))
    }

    func testCreationCreditIsNotAddedToRunningDuration() {
        var meter = VoiceCostMeter()
        meter.created()
        XCTAssertEqual(meter.estimatedSeconds(now: 1000), 15)
        meter.started(now: 1000)
        XCTAssertEqual(meter.estimatedSeconds(now: 1005), 15)
        XCTAssertEqual(meter.estimatedSeconds(now: 1090), 90)
        XCTAssertEqual(meter.estimatedUSD(now: 1900)!, 0.75, accuracy: 0.000001)
    }

    func testCumulativeReceiptsReplaceRatherThanSumAndContinueTiming() {
        var meter = VoiceCostMeter()
        meter.started(now: 100)
        meter.update(seconds: 30, now: 131)
        meter.update(seconds: 60, now: 162)
        XCTAssertEqual(meter.estimatedSeconds(now: 172), 70)
        meter.update(seconds: 75.5, now: 177, final: true)
        XCTAssertEqual(meter.estimatedSeconds(now: 1000), 75.5)
    }

    func testDisconnectFreezesEstimateAndFinalReceiptCanCorrectIt() {
        var meter = VoiceCostMeter()
        meter.started(now: 100)
        meter.finish(now: 190)
        XCTAssertEqual(meter.estimatedSeconds(now: 500), 90)
        meter.update(seconds: 91, now: 500)
        XCTAssertEqual(meter.estimatedSeconds(now: 600), 90)
        meter.update(seconds: 88.25, now: 600, final: true)
        meter.finish(now: 700)
        XCTAssertEqual(meter.estimatedSeconds(now: 1000), 88.25)
    }

    func testInvalidReceiptsDoNotPoisonEstimate() {
        var meter = VoiceCostMeter()
        meter.started(now: 100)
        for seconds in [-1.0, .nan, .infinity] { meter.update(seconds: seconds, now: 150, final: true) }
        XCTAssertEqual(meter.estimatedSeconds(now: 160), 60)
        meter = VoiceCostMeter()
        XCTAssertNil(meter.estimatedSeconds(now: 200))
    }
}
