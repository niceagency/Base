//// Created by Nice Agency

import XCTest
@testable import Base

struct TestObject: Codable, Equatable {
    let name: String
    let number: Int
}

struct CamelCaseTestObject: Codable, Equatable {
    let keyOne: String
    let keyTwo: Int
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
        let decodedTestObject = resource.parse(testObjectAsData, withDecoder: resource.decoder)
        let expectedObject = TestObject(name: "test", number: 1)
        
        switch decodedTestObject {
        case .success(let object):
            XCTAssertEqual(object, expectedObject)
        case .error:
            XCTFail("did not decode object")
        }
    }
    
    func testDefaultDecoderWillFailWithIncorrectKeys() {
        
        let jsonString = """
        {"key_one":"value1", "key_two": 2}
        """
        
        guard let testObjectAsData = jsonString.data(using: .utf8) else {
            fatalError("failed to encode JSON string to data")
        }
        
        // using default decoder - should fail
        let resource = Resource<CamelCaseTestObject>(endpoint: "test")
        let decodedTestObject = resource.parse(testObjectAsData, withDecoder: resource.decoder)
        
        if case let Result.error(error) = decodedTestObject {
            XCTAssertTrue(error is DecodingError, "failed to decode as keys are missing")
        }
    }
    
    func testResourceCanDecodeWithCustomDecoder() {
        
        let jsonString = """
        {"key_one":"value1", "key_two": 2}
        """
        
        guard let testObjectAsData = jsonString.data(using: .utf8) else {
            fatalError("failed to encode JSON string to data")
        }
        
        // using custom decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let resource = Resource<CamelCaseTestObject>(endpoint: "test", decoder: decoder)
        
        let decodedTestObject = resource.parse(testObjectAsData, withDecoder: resource.decoder)
        let expectedObject = CamelCaseTestObject(keyOne: "value1", keyTwo: 2)
        
        switch decodedTestObject {
        case .success(let object):
            XCTAssertEqual(object, expectedObject)
        case .error:
            XCTFail("did not decode object")
        }
    }
}
