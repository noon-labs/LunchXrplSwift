import XCTest
@testable import LunchXrplSwift

final class AccountLinesTests: XCTestCase {
    func testAccountLines() async throws {
        let wallet = try? Wallet.generateWallet(node: Servers.mainnet.rawValue).1
        
        let accountLinesWithPeer = try await wallet?.getAccountLines(address: "rDo1w1RULXBMqmDpy3sPmkaiGRfxx1iGAX", peer: "rMxCKbEDwqr76QuheSUMdEGf4B9xJ8m5De")
        print("KUSH peer \(accountLinesWithPeer?.account)")
        print("KUSH peer \(accountLinesWithPeer?.lines)")
        XCTAssertNotNil(accountLinesWithPeer)
        let accountLines = try await wallet?.getAccountLines(address: "rDo1w1RULXBMqmDpy3sPmkaiGRfxx1iGAX", peer: nil)
        print("KUSH peer \(accountLines?.account)")
        print("KUSH peer \(accountLines?.lines)")
        
        XCTAssertNotNil(accountLines)
    }
}
