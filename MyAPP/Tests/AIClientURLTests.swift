import XCTest
@testable import MyAPP

final class AIClientURLTests: XCTestCase {
    
    func testProxyURLIsCorrect() {
        // Test that AIClient uses the correct Vercel proxy URL
        let expectedURL = "https://my-ios-app.vercel.app/api/ai"
        
        // Access the private proxyURL through reflection for testing
        let client = AIClient.shared
        let mirror = Mirror(reflecting: client)
        
        var proxyURL: String?
        for child in mirror.children {
            if child.label == "proxyURL" {
                if let url = child.value as? URL {
                    proxyURL = url.absoluteString
                }
                break
            }
        }
        
        XCTAssertNotNil(proxyURL, "proxyURL should exist")
        XCTAssertEqual(proxyURL, expectedURL, "Proxy URL should match expected Vercel endpoint")
    }
    
    func testAIClientSingletonExists() {
        // Test that AIClient.shared exists and is accessible
        let client = AIClient.shared
        XCTAssertNotNil(client, "AIClient.shared should not be nil")
    }
}
