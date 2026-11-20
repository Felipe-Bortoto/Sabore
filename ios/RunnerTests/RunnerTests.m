#import <XCTest/XCTest.h>

@interface RunnerTests : XCTestCase
@end

@implementation RunnerTests

- (void)testApplicationDelegateExists {
  XCTAssertNotNil(NSClassFromString(@"AppDelegate"));
}

@end
