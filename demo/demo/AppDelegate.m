//
//  AppDelegate.m
//  demo
//
//  Created by K.H.Wang on 2016/12/20.
//  Copyright © 2016年 KH. All rights reserved.
//

#import "AppDelegate.h"
@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.demoVC=[[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
    [self.window.contentView addSubview:self.demoVC.view];
    
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
