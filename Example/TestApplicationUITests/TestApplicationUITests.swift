//
//  TestApplicationUITests.swift
//  TestApplicationUITests
//
//  Created by Sion Sasson on 31/03/2022.
//

import XCTest
import Foundation

class TestApplicationUITests: XCTestCase {
  
    func testStartingDontAllowFlow() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .photos)
        app.launch()

        app/*@START_MENU_TOKEN@*/.staticTexts["Pick image"]/*[[".buttons[\"Pick image\"].staticTexts[\"Pick image\"]",".staticTexts[\"Pick image\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Allow"]/*[[".buttons[\"Allow\"].staticTexts[\"Allow\"]",".staticTexts[\"Allow\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        addUIInterruptionMonitor(withDescription: "Permission alert") { alert in
            alert.buttons["Don’t Allow"].tap()
            return true
        }
        app.tap()
        
        XCTAssertEqual(app.staticTexts.element(matching:.any, identifier: "error").label, "The operation couldn’t be completed. (ImagePickerService.ImagePickerServiceError error 2.)")
        
        app.staticTexts["Pick image"].tap()
    }
    
    func testStartingDontAllowFlow2() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .photos)
        app.launch()

        app/*@START_MENU_TOKEN@*/.staticTexts["Pick image"]/*[[".buttons[\"Pick image\"].staticTexts[\"Pick image\"]",".staticTexts[\"Pick image\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.staticTexts["Dont Allow"].tap()

        XCTAssertEqual(app.staticTexts.element(matching:.any, identifier: "error").label, "The operation couldn’t be completed. (ImagePickerService.ImagePickerServiceError error 2.)")
    }
    
    func testStartingAllowFlow() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .photos)
        app.launch()

        app/*@START_MENU_TOKEN@*/.staticTexts["Pick image"]/*[[".buttons[\"Pick image\"].staticTexts[\"Pick image\"]",".staticTexts[\"Pick image\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Allow"]/*[[".buttons[\"Allow\"].staticTexts[\"Allow\"]",".staticTexts[\"Allow\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        addUIInterruptionMonitor(withDescription: "Permission alert") { alert in
            alert.buttons["Allow Access to All Photos"].tap()
            return true
        }
        app.tap()
        
        let exp = expectation(description: "\(#function)\(#line)")
        
        let image = app.scrollViews.otherElements.images.firstMatch
        if image.waitForExistence(timeout: 5) {
            image.tap()
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5)
    }
    
    func testOpenCameraFlow() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .photos)
        app.launch()

        app.staticTexts["Open camera"].tap()
        XCTAssertEqual(app.staticTexts.element(matching:.any, identifier: "error").label, "The operation couldn’t be completed. (ImagePickerService.ImagePickerServiceError error 0.)")
    }
    
    func testOpenCloseFlow() throws {
        let app = XCUIApplication()
        app.resetAuthorizationStatus(for: .photos)
        app.launch()

        app.staticTexts["Pick image"].tap()
        app.staticTexts["Close"].tap()
        XCTAssertEqual(app.staticTexts.element(matching:.any, identifier: "error").label, "The operation couldn’t be completed. (ImagePickerService.ImagePickerServiceError error 4.)")
    }
}
