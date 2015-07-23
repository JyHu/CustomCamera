//
//  AUUSliderMenuView.m
//  CustomCameraWithFilter
//
//  Created by 胡金友 on 15/7/19.
//  Copyright (c) 2015年 胡金友. All rights reserved.
//

#import "AUUSliderMenuView.h"
#import "AUUMacro.h"
#import "AUUColorCategory.h"
#import "AUUFilterFactory.h"

@interface AUUSliderMenuView()<UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) NSArray *p_data;
@property (copy, nonatomic) AUUSliderMenuSelectedResultBlock p_menuSelectedBlock;

@end

@implementation AUUSliderMenuView

- (id)initWithData:(NSArray *)data
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self)
    {
        _p_data = data;
        
        [self initilization];
    }
    return self;
}

- (void)initilization
{
    self.menuTable = [[UITableView alloc] initWithFrame:CGRectMake(kScreenSize.width / 3.0 * 2, 0,
                                                                   kScreenSize.width / 3.0, kScreenSize.height)
                                                  style:UITableViewStyleGrouped];
    self.menuTable.delegate = self;
    self.menuTable.dataSource = self;
    self.menuTable.backgroundColor = [UIColor clearColor];
    [self addSubview:self.menuTable];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 : _p_data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reUsefulIdentifier = @"reUsefulIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reUsefulIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reUsefulIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
        cell.backgroundColor = [UIColor randomColorWithAlpha:0.3];
    }
    
    if (indexPath.section == 0)
    {
        cell.textLabel.text = @"取消滤镜";
    }
    else
    {
        NSDictionary *dict = _p_data[indexPath.row];
        cell.textLabel.text = dict[AUUFilterLocalizedNameKey];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? AUUZero : 10.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return AUUZero;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.p_menuSelectedBlock)
    {
        _p_menuSelectedBlock(indexPath.section == 0 ? AUUSelectionCancel : indexPath.row);
    }
}

- (void)selectedItemAtIndex:(AUUSliderMenuSelectedResultBlock)completion
{
    _p_menuSelectedBlock = completion;
}

- (void)show
{
    [[[UIApplication sharedApplication] keyWindow] addSubview:self];
    _menuTable.alpha = 0;
    
    [UIView animateWithDuration:defaultAnimationDuration animations:^{
        _menuTable.alpha = 1;
    }];
}

- (void)dismiss
{
    [UIView animateWithDuration:defaultAnimationDuration animations:^{
        _menuTable.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self dismiss];
}

@end
