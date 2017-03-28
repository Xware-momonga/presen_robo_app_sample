//
//  PageViewController.m
//  MiniPeppre
//
//  Created by y-kawashima on 2017/02/07.
//  Copyright © 2017年 Xware Corporation. All rights reserved.
//

#import "PageViewController.h"

#import "MiniPeppre.h"

/**
 *  ページ画面のコントローラ
 */
@interface PageViewController ()

/// 画像を表示するオブジェクト
@property(nonatomic, weak) IBOutlet UIImageView *imageView;
/// 画像ファイルパス
@property(nonatomic, strong) NSString *imageFilePath;

@end

@implementation PageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    /// プレゼンID, ページID で生成された画像ファイルから画像を読み込み、表示します
    self.imageView.image = [UIImage imageWithContentsOfFile:self.imageFilePath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  画面が表示される前に呼ばれる関数
 *
 *  @param animated アニメーションの有無
 */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    /// ナビゲーションバーを非表示にします
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - イベント

/**
 *  画面タップで呼ばれるメソッド
 *
 *  画面タップで、ナビゲーションの表示、非表示を切り替えます。
 *
 *  @param sender セレクタにメッセージを送信したオブジェクト
 */
- (IBAction)selectorTapGestureRecognizer:(UITapGestureRecognizer *)sender {
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
}

#pragma mark - メソッド

/**
 *  ページの指定
 *
 *  表示したいページをプレゼンID, ページID で指定します。
 *  指定された ID からページの画像ファイルパスを生成し、変数に保存します。
 *
 *  @param presenID プレゼンID
 *  @param pageID   ページID
 */
- (void)openPresen:(NSString *)presenID page:(NSString *)pageID {
    NSString *contentsDirectory = [MiniPeppre contentsDirectory];
    NSString *imageFilePath = [[contentsDirectory stringByAppendingPathComponent:presenID] stringByAppendingPathComponent:pageID];
    self.imageFilePath = imageFilePath;
}

@end
