//
//  SQUGradespeedDriver.h
//  QuickHAC
//
//  Created by Tristan Seifert on 1/2/14.
//  See README.MD for licensing and copyright information.
//

#import "SQUGradebookDriver.h"

@interface SQUGradespeedDriver : SQUGradebookDriver <SQUGradebookDriverProtocol> {
	NSDateFormatter *_gradespeedDateFormatter;
}

@end
