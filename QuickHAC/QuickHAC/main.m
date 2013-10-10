//
//  main.m
//  QuickHAC
//
//  Created by Tristan Seifert on 05/07/2013.
//  See README.MD for licensing and copyright information.
//

#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <objc/message.h>

#import "SQUAppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([SQUAppDelegate class]));
    }
}

void MethodSwizzle(Class c, SEL origSEL, SEL overrideSEL) {
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method overrideMethod = class_getInstanceMethod(c, overrideSEL);

    if(class_addMethod(c, origSEL, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(c, overrideSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, overrideMethod);
    }
}