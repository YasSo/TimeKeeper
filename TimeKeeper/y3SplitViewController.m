//
//  y3SplitViewController.m
//  TimeKeeper
//
//  Created by Yasuo Miyoshi on 2017/02/14.
//  Copyright © 2017 Kochi University. All rights reserved.
//

#import "y3SplitViewController.h"
#import "y3DetailViewController.h"

@interface y3SplitViewController ()

@end

@implementation y3SplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    UINavigationController *nvc = self.viewControllers.count > 1 ? [self.viewControllers lastObject] : nil;
//    if (nvc == nil) return;
//    nvc.navigationBar.barStyle = UIBarStyleBlack;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (y3DetailViewController *)getDetailViewController {
    UINavigationController *nvc = self.viewControllers.count > 1 ? [self.viewControllers lastObject] : nil;
//    UINavigationController *nvc = [self.viewControllers lastObject];
    if (nvc == nil) return nil;
    return (y3DetailViewController *)nvc.topViewController;
    return nil;
}

- (IBAction)pushResetKey:(id)sender {
    [[self getDetailViewController] resetCounter];
}

- (IBAction)pushStartKey:(id)sender {
    [[self getDetailViewController] startCounter];
}

- (IBAction)pushBellKey:(id)sender {
    [[self getDetailViewController] ringBell:1];
}

- (NSArray *)keyCommands {
    return @[
             [UIKeyCommand keyCommandWithInput: UIKeyInputLeftArrow
                                 modifierFlags: 0
                                        action: @selector(pushResetKey:)],
             [UIKeyCommand keyCommandWithInput: @" "
                                 modifierFlags: 0
                                        action: @selector(pushStartKey:)],
             [UIKeyCommand keyCommandWithInput: @"b"
                                 modifierFlags: 0
                                        action: @selector(pushBellKey:)],
             ];
}

@end
