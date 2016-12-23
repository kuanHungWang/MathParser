//
//  DemoViewController.h
//  demo
//
//  Created by K.H.Wang on 2016/12/20.
//  Copyright © 2016年 KH. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DemoViewController : NSViewController

@property (weak) IBOutlet NSTextField *textField;
@property (weak) IBOutlet NSTextField *labelResult;
@property (weak) IBOutlet NSTextField *labelErrorRange;
@property (weak) IBOutlet NSTextField *labelErrorMessage;
@property (weak) IBOutlet NSTextField *labelErrorStage;
@property (weak) IBOutlet NSTextField *labelFunctionInfo;

@end
