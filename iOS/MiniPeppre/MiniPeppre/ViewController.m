//
//  ViewController.m
//  MiniPeppre
//
//  Created by y-kawashima on 2017/02/07.
//  Copyright © 2017年 Xware Corporation. All rights reserved.
//

#import "ViewController.h"

#import "Const.h"
#import "MiniPeppre.h"
#import "PageViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerURLEncodedFormRequest.h>
#import <SVProgressHUD/SVProgressHUD.h>

/**
 *  トップ画面（「更新」ボタンが表示されている画面）のコントローラ
 */

@interface ViewController ()

/// Pepper からの指示を受け取るサーバ機能（GCDWebServer）の変数
@property(nonatomic, strong) GCDWebServer *webServer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    /// Pepper から指示を受け取れるようにサーバ機能を開始する
    [self startWebServer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  画面が表示される前に呼ばれるメソッド
 *
 *  @param animated アニメーションの有無
 */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    /// ナビゲーションバーを表示します
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

#pragma mark - UIイベント処理

/**
 *  「更新」ボタンを押下した際に呼ばれるメソッド
 *
 *  @param sender ボタンのオブジェクト
 */
- (IBAction)touchUpInsideDownloadButton:(id)sender {
    /// プレゼン画像をダウンロードします
    [self downloadImages];
}

#pragma mark - コンテンツ取得

/**
 *  プレゼン登録画像のダウンロード処理
 *
 *  1. プレゼン登録画像取得用APIに接続し、zip ファイルをダウンロードします
 *  2. ダウンロードした zip ファイルを解凍します
 */
- (void)downloadImages {
    /// ローディング画面を表示します
    [SVProgressHUD setMinimumSize:CGSizeMake(100, 100)];
    [SVProgressHUD showWithStatus:@"ダウンロード中"];

    /// URL 文字列から NSURLRequest を作成します
    NSURL *url = [NSURL URLWithString:API_PRESEN_IMAGE_DOWNLOAD];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    /// セッションを作成します
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    /// ダウンロード処理を定義します
    NSURLSessionDownloadTask *downloadTask =
        [manager downloadTaskWithRequest:request
            progress:nil
            destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
              /// zip ファイルの保存先を定義する関数

              /// zip ファイル自体は解凍後、不要になるため、テンポラリディレクトリに保存します
              /// ファイル名は、推奨の名前（suggestedFilename）にします
              NSURL *temporaryDirectoryURL = [NSURL fileURLWithPath:NSTemporaryDirectory()];
              NSURL *destinationURL = [temporaryDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];

              /// ダウンロード済みの zip ファイルが存在すると、ダウンロードに失敗するため、事前に同名のファイルを削除します
              [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];

              return destinationURL;
            }
            completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
              /// ダウンロード完了（失敗）時に呼ばれるメソッド

              if (error) {
                  /// ダウンロード失敗時の処理

                  /// ローディング画面に「失敗」と表示し、0.5 秒後に消します
                  [SVProgressHUD showErrorWithStatus:@"失敗"];
                  [SVProgressHUD dismissWithDelay:0.5];
              } else {
                  /// ダウンロード成功時の処理

                  /// ローディング画面に「解凍中」と表示します
                  [SVProgressHUD showWithStatus:@"解凍中"];

                  /// zip ファイルの解凍先を取得します
                  NSString *contentsDirectory = [MiniPeppre contentsDirectory];

                  /// ダウンロードした zip ファイルを解凍します
                  /// 解凍完了時にイベントを取得したいため、delegate に self を設定します
                  BOOL status = [SSZipArchive unzipFileAtPath:filePath.path toDestination:contentsDirectory delegate:self];
                  if (!status) {
                      /// zip ファイルの解凍に失敗した場合

                      /// ローディング画面に「失敗」と表示し、0.5 秒後に消します
                      [SVProgressHUD showErrorWithStatus:@"失敗"];
                      [SVProgressHUD dismissWithDelay:0.5];
                  }
              }
            }];

    /// ダウンロード処理を開始します
    [downloadTask resume];
}

#pragma mark - SSZipArchiveDelegate

/**
 *  zip ファイル解凍完了後に呼ばれるメソッド
 */
- (void)zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath {
    /// ローディング画面に「完了」と表示し、0.5 秒後に消します
    [SVProgressHUD showSuccessWithStatus:@"完了"];
    [SVProgressHUD dismissWithDelay:0.5];
}

#pragma mark - Pepperからのリクエスト処理

/**
 *  Pepper からの指示を受け取れるようにサーバ機能を開始
 */
- (void)startWebServer {
    __weak typeof(self) weakSelf = self;

    /// サーバ機能を生成します
    self.webServer = [[GCDWebServer alloc] init];

    /// Pepper からの指示を受け取れるようにリクエストURLを定義します
    [self.webServer addHandlerForMethod:@"GET"
                                   path:@"/pepper"
                           requestClass:[GCDWebServerDataRequest class]
                      asyncProcessBlock:^(GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {

                        /// Pepper からの指示（command）を取得します
                        NSString *command = request.query[@"command"];

                        /// 指示に合わせて、処理を行います
                        if ([command isEqualToString:@"open"]) {
                            /// ページを開く

                            /// Pepper から送られたプレゼンID、ページID を取得します
                            NSString *presenID = request.query[@"presenid"];
                            NSString *pageID = request.query[@"pageid"];

                            dispatch_async(dispatch_get_main_queue(), ^{
                              /// ページを開くメソッドを呼びます
                              [weakSelf openPresen:presenID page:pageID];
                            });
                        } else if ([command isEqualToString:@"close"]) {
                            /// ページを閉じる

                            dispatch_async(dispatch_get_main_queue(), ^{
                              /// ページを閉じるメソッドを呼びます
                              [weakSelf closePage];
                            });
                        }

                        /// Pepper に HTTPスターテス 200（Success OK）を返却します
                        GCDWebServerResponse *response = [GCDWebServerResponse responseWithStatusCode:200];
                        completionBlock(response);
                      }];

    /// サーバ機能を開始します
    [self.webServer startWithPort:8080 bonjourName:nil];
}

/**
 *  ページを開く
 *
 *  Pepper から送られたプレゼンID、ページID を指定して、ページを表示します。
 *
 *  @param presenID プレゼンID
 *  @param pageID   ページID
 */
- (void)openPresen:(NSString *)presenID page:(NSString *)pageID {
    /// ページを表示する画面を生成します
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"PageViewController" bundle:nil];
    PageViewController *pageViewController = [storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];

    /// 表示するページを指定します
    [pageViewController openPresen:presenID page:pageID];

    /// ページ画面を表示します
    /// ページ画面が複数ページ分表示されないように、1番目（最背面）にトップ画面（この画面）、2番目（最前面）に生成した画面を配置して表示します
    NSArray *viewControllers = @[ self, pageViewController ];
    [self.navigationController setViewControllers:viewControllers animated:YES];
}

/**
 *  ページを閉じる
 */
- (void)closePage {
    /// ページ画面をすべて閉じて、トップ画面を表示します
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
