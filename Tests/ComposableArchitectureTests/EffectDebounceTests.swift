import ComposableArchitecture
import ReactiveSwift
import XCTest

final class EffectDebounceTests: XCTestCase {
  func testDebounce() {
    let scheduler = TestScheduler()
    var values: [Int] = []

    func runDebouncedEffect(value: Int) {
      struct CancelToken: Hashable {}

      Effect(value: value)
        .debounce(id: CancelToken(), interval: 1, scheduler: scheduler)
        .startWithValues { values.append($0) }
    }

    runDebouncedEffect(value: 1)

    // Nothing emits right away.
    XCTAssertEqual(values, [])

    // Waiting half the time also emits nothing
    scheduler.advance(by: .milliseconds(500))
    XCTAssertEqual(values, [])

    // Run another debounced effect.
    runDebouncedEffect(value: 2)

    // Waiting half the time emits nothing because the first debounced effect has been canceled.
    scheduler.advance(by: .milliseconds(500))
    XCTAssertEqual(values, [])

    // Run another debounced effect.
    runDebouncedEffect(value: 3)

    // Waiting half the time emits nothing because the second debounced effect has been canceled.
    scheduler.advance(by: .milliseconds(500))
    XCTAssertEqual(values, [])

    // Waiting the rest of the time emits the final effect value.
    scheduler.advance(by: .milliseconds(500))
    XCTAssertEqual(values, [3])

    // Running out the scheduler
    scheduler.run()
    XCTAssertEqual(values, [3])
  }

  func testDebounceIsLazy() {
    let scheduler = TestScheduler()
    var values: [Int] = []
    var effectRuns = 0

    func runDebouncedEffect(value: Int) {
      struct CancelToken: Hashable {}

      Effect.deferred { () -> SignalProducer<Int, Never> in
        effectRuns += 1
        return Effect(value: value)
      }
      .debounce(id: CancelToken(), interval: 1, scheduler: scheduler)
      .startWithValues { values.append($0) }
    }

    runDebouncedEffect(value: 1)

    XCTAssertEqual(values, [])
    XCTAssertEqual(effectRuns, 0)

    scheduler.advance(by: .milliseconds(500))

    XCTAssertEqual(values, [])
    XCTAssertEqual(effectRuns, 0)

    scheduler.advance(by: .milliseconds(500))

    XCTAssertEqual(values, [1])
    XCTAssertEqual(effectRuns, 1)
  }
}
