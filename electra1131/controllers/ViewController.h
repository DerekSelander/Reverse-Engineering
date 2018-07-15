//
//  ViewController.h
//
//  Copyright © 2018 Electra Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

{
    
    UIImageView *_logoView;
    UIStackView *_jailbreakButtonStackView;
    UIStackView *_creditsLabelStackView;
    UIView *_bottomPanelView;
    UIView *_tweaksContainerView;
}

@property(nonatomic) UILabel *compatibilityLabel;
@property(nonatomic) UISwitch *enableTweaks;
@property(nonatomic) UIButton *setNonce;
@property(nonatomic) UIButton *jailbreak;

+ (id)currentViewController;
- (void)dealloc;
- (void)enableTweaksChanged:(id)arg1;
- (long long)preferredStatusBarStyle;
- (void)restarting;
- (void)displaySnapshotWarning;
- (void)displaySnapshotNotice;
- (void)cydiaDone;
- (void)installingCydia;
- (void)removingLiberiOS;
- (void)tappedOnHyperlink:(id)arg1;
- (void)tappedOnSetNonce:(id)arg1;
- (void)doit:(id)arg1;
- (void)credits:(id)arg1;
- (void)didReceiveMemoryWarning;
- (void)viewDidLoad;
- (void)shareElectra;
- (void)checkVersion;
- (void)updateProgressFromNotification:(id)arg1;

@end

