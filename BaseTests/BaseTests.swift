//// Created by Nice Agency

import XCTest
@testable import Base

struct TestObject: Codable, Equatable {
    let name: String
    let number: Int
}

class BaseTests: XCTestCase {
    
    func testResourceIsParsable() {
        
    let jsonString = """
    {"name":"test","number":1}
    """
        
        guard let testObjectAsData = jsonString.data(using: .utf8) else {
            fatalError("failed to encode JSON string to data")
        }
        
        let resource = Resource<TestObject>(endpoint: "test")
       
        let decodedTestObject = resource.parse(testObjectAsData)
        
        let expectedObject = TestObject(name: "test", number: 1)
        
        switch decodedTestObject {
            
        case .success(let object):
            XCTAssertEqual(object, expectedObject)
        case .error:
            XCTFail("did not decode object")
        }
    }
    
    
}
