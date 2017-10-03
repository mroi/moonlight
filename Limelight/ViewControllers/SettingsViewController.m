//
//  SettingsViewController.m
//  Moonlight
//
//  Created by Diego Waxemberg on 10/27/14.
//  Copyright (c) 2014 Moonlight Stream. All rights reserved.
//

#import "SettingsViewController.h"
#import "TemporarySettings.h"
#import "DataManager.h"

#define BITRATE_INTERVAL 10000 // in kbps

@implementation SettingsViewController {
    NSInteger _bitrate;
    NSArray *numbers;
}
static NSString* bitrateFormat = @"Bitrate: %d Mbps";


- (void)viewDidLoad {
    [super viewDidLoad];
    
    DataManager* dataMan = [[DataManager alloc] init];
    TemporarySettings* currentSettings = [dataMan getSettings];
    
    // Bitrate is persisted in kbps
    _bitrate = [currentSettings.bitrate integerValue];
    NSInteger framerate = [currentSettings.framerate integerValue] == 30 ? 0 : 1;
    NSInteger resolution;
    if ([currentSettings.height integerValue] == 720) {
        resolution = 0;
    } else if ([currentSettings.height integerValue] == 1080) {
        resolution = 1;
    } else {
        resolution = 0;
    }
    NSInteger onscreenControls = [currentSettings.onscreenControls integerValue];
    
    [self.resolutionSelector setSelectedSegmentIndex:resolution];
    [self.resolutionSelector addTarget:self action:@selector(newResolutionFpsChosen) forControlEvents:UIControlEventValueChanged];
    [self.framerateSelector setSelectedSegmentIndex:framerate];
    [self.framerateSelector addTarget:self action:@selector(newResolutionFpsChosen) forControlEvents:UIControlEventValueChanged];
    [self.onscreenControlSelector setSelectedSegmentIndex:onscreenControls];


    numbers = @[@(1), @(2), @(3), @(4), @(5), @(6), @(7), @(8), @(9), @(10)];
    NSInteger numberOfSteps = ((float)[numbers count]);
    self.bitrateSlider.maximumValue = numberOfSteps;
    self.bitrateSlider.minimumValue = 1;
    
    self.bitrateSlider.continuous = YES;

    [self.bitrateSlider setValue:(_bitrate / BITRATE_INTERVAL) animated:YES];
    [self.bitrateSlider addTarget:self action:@selector(bitrateSliderMoved) forControlEvents:UIControlEventValueChanged];
    [self updateBitrateText];
}

- (void) newResolutionFpsChosen {
    NSInteger frameRate = [self getChosenFrameRate];
    NSInteger resHeight = [self getChosenStreamHeight];
    NSInteger defaultBitrate;
    
    // 1080p60 is 20 Mbps
    if (frameRate == 60 && resHeight == 1080) {
        defaultBitrate = 30000;
    }
    // 720p60 and 1080p30 are 10 Mbps
    else if (frameRate == 60 || resHeight == 1080) {
        defaultBitrate = 10000;
    }
    // 720p30 is 5 Mbps
    else {
        defaultBitrate = 5000;
    }
    
    _bitrate = defaultBitrate;
    [self.bitrateSlider setValue:defaultBitrate / BITRATE_INTERVAL animated:YES];
    
    [self updateBitrateText];
}

- (void) bitrateSliderMoved {
    NSUInteger index = (NSUInteger)(self.bitrateSlider.value);
    [self.bitrateSlider setValue:index animated:NO];
    
    _bitrate = BITRATE_INTERVAL * (int)self.bitrateSlider.value;
    [self updateBitrateText];
}

- (void) updateBitrateText {
    // Display bitrate in Mbps
    [self.bitrateLabel setText:[NSString stringWithFormat:bitrateFormat, _bitrate / 1000]];
}

- (NSInteger) getChosenFrameRate {
    return [self.framerateSelector selectedSegmentIndex] == 0 ? 30 : 60;
}

- (NSInteger) getChosenStreamHeight {
    return [self.resolutionSelector selectedSegmentIndex] == 0 ? 720 : 1080;
}

- (NSInteger) getChosenStreamWidth {
    return [self getChosenStreamHeight] == 720 ? 1280 : 1920;
}

- (void) saveSettings {
    DataManager* dataMan = [[DataManager alloc] init];
    NSInteger framerate = [self getChosenFrameRate];
    NSInteger height = [self getChosenStreamHeight];
    NSInteger width = [self getChosenStreamWidth];
    NSInteger onscreenControls = [self.onscreenControlSelector selectedSegmentIndex];
    [dataMan saveSettingsWithBitrate:_bitrate framerate:framerate height:height width:width onscreenControls:onscreenControls];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


@end
