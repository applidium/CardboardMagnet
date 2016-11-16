//
//  MEAppDelegate.m
//  MagnetExperiment
//
//  Created by Thibault Farnier on 25/07/2016.
//  Copyright © 2016 Thibault Farnier. All rights reserved.
//

#import "MEAppDelegate.h"
#import "MEGameViewController.h"

@implementation MEAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = [[UINavigationController alloc]initWithRootViewController:[MEGameViewController new]];

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
