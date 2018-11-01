//// Created by Nice Agency

import XCTest
@testable import Base

struct TestObject: Codable, Equatable, HttpData {
    let name: String
    let number: Int
}

struct CamelCaseTestObject: Codable, Equatable, HttpData {
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
    
    func testHTTPMethodCanEncodeData() {
        let encoder = JSONEncoder()
        let testObject = TestObject(name: "1", number: 3)
        let jsonData = try? encoder.encode(testObject)
        let resource = Resource<TestObject>(endpoint: "/",
                                            method: HttpMethod.post(jsonData))
        
        let request = URLRequest(resource: resource,
                                 baseURL: URL(fileURLWithPath: ""),
                                 additionalHeaders: [],
                                 requestBehaviour: EmptyRequestBehavior())
        
        XCTAssertNotNil(request)
        XCTAssertNotNil(request?.httpBody)
        XCTAssertEqual(request?.httpBody, jsonData)
    }
    
    func testHTTPMethodCanEncodeCodableObject() {
        let testObject = TestObject(name: "1", number: 3)
        let resource = Resource<TestObject>(endpoint: "/",
                                            method: HttpMethod.post(testObject))
        
        let request = URLRequest(resource: resource,
                                 baseURL: URL(fileURLWithPath: ""),
                                 additionalHeaders: [],
                                 requestBehaviour: EmptyRequestBehavior())
        
        XCTAssertNotNil(request)
        XCTAssertNotNil(request?.httpBody)
    }
    
    func testHTTPMethodCanEncodeDictionaryObject() {
        let testObject = ["1": 3]
        let resource = Resource<TestObject>(endpoint: "/",
                                            method: HttpMethod.post(testObject))
        
        let request = URLRequest(resource: resource,
                                 baseURL: URL(fileURLWithPath: ""),
                                 additionalHeaders: [],
                                 requestBehaviour: EmptyRequestBehavior())
        
        XCTAssertNotNil(request)
        XCTAssertNotNil(request?.httpBody)
    }
}
