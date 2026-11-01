// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get retry => '再試行';

  @override
  String get cancel => 'キャンセル';

  @override
  String get save => '保存';

  @override
  String get add => '追加';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get search => '検索';

  @override
  String get close => '閉じる';

  @override
  String get confirm => '確認';

  @override
  String get emptyTitle => 'まだ何もありません';

  @override
  String get errorTitle => '問題が発生しました';

  @override
  String get networkError => 'サーバーに接続できません。接続を確認してください。';

  @override
  String get invalidCredentials => 'メールアドレスまたはパスワードが正しくありません。';

  @override
  String get accountLocked => '試行回数が多すぎます。後でもう一度お試しください。';

  @override
  String get rateLimited => 'リクエストが多すぎます。少しお待ちください。';

  @override
  String get signIn => 'サインイン';

  @override
  String get signOut => 'サインアウト';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get name => '名前';

  @override
  String get language => '言語';

  @override
  String get requiredField => '必須';

  @override
  String get invalidValue => '無効な値です';

  @override
  String get total => '合計';

  @override
  String get subtotal => '小計';

  @override
  String get discount => '割引';

  @override
  String get tax => '税';

  @override
  String get serviceCharge => 'サービス料';

  @override
  String get status => 'ステータス';

  @override
  String get date => '日付';

  @override
  String get amount => '金額';

  @override
  String get quantity => '数量';

  @override
  String get notes => 'メモ';

  @override
  String get reason => '理由';

  @override
  String get refresh => '更新';

  @override
  String welcomeTable(String table) {
    return 'テーブル $table';
  }

  @override
  String get menu => 'メニュー';

  @override
  String get cart => 'カート';

  @override
  String get addToCart => 'カートに追加';

  @override
  String get viewCart => 'カートを見る';

  @override
  String get emptyCart => 'カートは空です';

  @override
  String get chooseOption => 'オプションを選択';

  @override
  String get extras => '追加';

  @override
  String get specialInstructions => 'ご要望';

  @override
  String get placeOrder => '注文する';

  @override
  String get orderPlaced => '注文しました';

  @override
  String orderNumber(int number) {
    return '注文番号 $number';
  }

  @override
  String get trackOrder => '注文を追跡';

  @override
  String get payNow => '今すぐ支払う';

  @override
  String get payAtCounter => 'レジで支払う';

  @override
  String get onlinePaymentUnavailable =>
      'こちらではオンライン決済はまだご利用いただけません。レジでお支払いください。';

  @override
  String get paymentPending => '支払いの確認を待っています';

  @override
  String get receipt => '領収書';

  @override
  String get rateUs => 'ご感想をお聞かせください';

  @override
  String get submit => '送信';

  @override
  String get thanks => 'ありがとうございます！';

  @override
  String get callWaiter => '店員を呼ぶ';

  @override
  String get requestBill => 'お会計を依頼';

  @override
  String get callStaff => 'スタッフを呼ぶ';

  @override
  String get requestSent => '依頼を送信しました。スタッフに通知しました。';

  @override
  String get favorites => 'お気に入り';

  @override
  String get wishlist => 'ほしいもの';

  @override
  String get recentlyOrdered => '最近の注文';

  @override
  String get coupon => 'クーポンコード';

  @override
  String get apply => '適用';

  @override
  String get couponInvalid => 'このクーポンは使用できません';

  @override
  String get veg => 'ベジタリアン';

  @override
  String get nonVeg => '非ベジタリアン';

  @override
  String get egg => '卵';

  @override
  String get vegan => 'ヴィーガン';

  @override
  String get outOfStock => '売り切れ';

  @override
  String get myOrders => '注文履歴';

  @override
  String get profile => 'プロフィール';

  @override
  String get createAccount => 'アカウント作成';

  @override
  String get offers => '特典';

  @override
  String get qrInvalid => 'このQRコードは無効です。スタッフにお尋ねください。';

  @override
  String get noResults => '該当する商品がありません';

  @override
  String get allCategories => 'すべて';

  @override
  String get statusPendingPayment => '支払い待ち';

  @override
  String get statusPlaced => '新規';

  @override
  String get statusAccepted => '受付済み';

  @override
  String get statusPreparing => '調理中';

  @override
  String get statusReady => '準備完了';

  @override
  String get statusServed => '提供済み';

  @override
  String get statusCompleted => '完了';

  @override
  String get statusCancelled => 'キャンセル';

  @override
  String get payUnpaid => '未払い';

  @override
  String get payPartial => '一部支払い';

  @override
  String get payPaid => '支払い済み';

  @override
  String get payPartRefund => '一部返金';

  @override
  String get payRefunded => '返金済み';

  @override
  String get kitchenNew => '新規';

  @override
  String get kitchenInProgress => '調理中';

  @override
  String get kitchenReady => '完了';

  @override
  String get accept => '受付';

  @override
  String get startPreparing => '開始';

  @override
  String get markReady => '完了';

  @override
  String get complete => '終了';

  @override
  String get delayed => '遅延';

  @override
  String minutesShort(int count) {
    return '$count分';
  }

  @override
  String get priority => '優先度';

  @override
  String get allStations => '全ステーション';

  @override
  String get noTickets => '現在注文はありません';

  @override
  String get connectionLost => '接続が切れました。再接続中…';

  @override
  String get takeaway => '持ち帰り';

  @override
  String get kitchenBranch => '店舗';

  @override
  String get dashboard => 'ダッシュボード';

  @override
  String get orders => '注文';

  @override
  String get menuManage => 'メニュー';

  @override
  String get tables => 'テーブル';

  @override
  String get staff => 'スタッフ';

  @override
  String get inventory => '在庫';

  @override
  String get finance => '財務';

  @override
  String get marketing => 'マーケティング';

  @override
  String get settings => '設定';

  @override
  String get revenue => '売上';

  @override
  String get ordersCount => '注文数';

  @override
  String get averageOrder => '平均注文額';

  @override
  String get cancellationRate => 'キャンセル率';

  @override
  String get topProducts => '人気商品';

  @override
  String get peakHours => 'ピーク時間';

  @override
  String get noDataYet => 'この期間のデータはまだありません';

  @override
  String get registerCafe => 'カフェを登録';

  @override
  String get cafeName => 'カフェ名';

  @override
  String get legalName => '正式な事業者名';

  @override
  String get country => '国';

  @override
  String get currency => '通貨';

  @override
  String get timezone => 'タイムゾーン';

  @override
  String get address => '住所';

  @override
  String get city => '市区町村';

  @override
  String get ownerName => 'お名前';

  @override
  String get pendingApproval => 'カフェは承認待ちです。その間に設定を進められます。';

  @override
  String get categories => 'カテゴリ';

  @override
  String get products => '商品';

  @override
  String get newCategory => '新しいカテゴリ';

  @override
  String get newProduct => '新しい商品';

  @override
  String get price => '価格';

  @override
  String get category => 'カテゴリ';

  @override
  String get tableNumber => 'テーブル番号';

  @override
  String get capacity => '席数';

  @override
  String get qrCode => 'QRコード';

  @override
  String get regenerateQr => 'QRを再発行';

  @override
  String get inviteStaff => 'スタッフを招待';

  @override
  String get role => '役割';

  @override
  String get ingredients => '材料';

  @override
  String get suppliers => '仕入先';

  @override
  String get stock => '在庫';

  @override
  String get unit => '単位';

  @override
  String get unitCost => '単価';

  @override
  String get stockIn => '入庫';

  @override
  String get expenses => '経費';

  @override
  String get sales => '売上';

  @override
  String get profitLoss => '損益';

  @override
  String get exportExcel => 'Excel出力';

  @override
  String get exportPdf => 'PDF出力';

  @override
  String get branding => 'ブランディング';

  @override
  String get primaryColor => 'メインカラー';

  @override
  String get coupons => 'クーポン';

  @override
  String get code => 'コード';

  @override
  String get percent => 'パーセント';

  @override
  String get acceptOrder => '受付';

  @override
  String get markServed => '提供済み';

  @override
  String get confirmCash => '現金を確認';

  @override
  String get refund => '返金';

  @override
  String get netProfit => '純利益';

  @override
  String get totalRevenue => '総収益';

  @override
  String get totalExpenses => '総経費';

  @override
  String get invitationLink => 'この招待トークンをスタッフに送ってください';

  @override
  String get cancelOrder => '注文をキャンセル';

  @override
  String get selectBranch => '店舗を選択';

  @override
  String get balance => '未払い残高';

  @override
  String get customers => '顧客';

  @override
  String get reservations => '予約';

  @override
  String get partySize => '人数';

  @override
  String get support => 'サポート';

  @override
  String get subject => '件名';

  @override
  String get message => 'メッセージ';

  @override
  String get cafes => 'カフェ';

  @override
  String get approve => '承認';

  @override
  String get suspend => '停止';

  @override
  String get activate => '有効化';

  @override
  String get plans => 'プラン';

  @override
  String get auditLogs => '監査ログ';

  @override
  String get health => 'システム状態';

  @override
  String get totalCafes => 'カフェ総数';

  @override
  String get activeCafes => '稼働中のカフェ';

  @override
  String get totalCustomers => '顧客';

  @override
  String get totalOrders => '総注文数';

  @override
  String get enrollMfa => '二段階認証を設定';

  @override
  String get mfaCode => '6桁のコード';

  @override
  String get mfaSecret => 'このキーを認証アプリに追加してください';

  @override
  String get grossByCurrency => '通貨別総売上';

  @override
  String get cafesByCountry => '国別カフェ数';

  @override
  String get activeSubscriptions => '有効なサブスクリプション';

  @override
  String get reasonPrompt => '理由を入力してください。監査ログに記録されます。';

  @override
  String get action => '操作';

  @override
  String get database => 'データベース';

  @override
  String get pendingCafes => '承認待ち';

  @override
  String get owner => 'オーナー';

  @override
  String get stActive => '有効';

  @override
  String get stInactive => '無効';

  @override
  String get stAvailable => '空席';

  @override
  String get stOccupied => '使用中';

  @override
  String get stReserved => '予約済み';

  @override
  String get stCleaning => '清掃中';

  @override
  String get stSuspended => '停止中';

  @override
  String get stRejected => '却下';

  @override
  String get stClosed => '閉鎖';

  @override
  String get stOpen => '対応中';

  @override
  String get stResolved => '解決済み';

  @override
  String get stInProgress => '進行中';

  @override
  String get stInvited => '招待済み';

  @override
  String get roleManager => 'マネージャー';

  @override
  String get roleCashier => 'レジ担当';

  @override
  String get roleWaiter => 'ホール担当';

  @override
  String get roleKitchen => 'キッチン担当';

  @override
  String get setPricesIncludeTax => '価格は税込み';

  @override
  String get setRequireAcceptance => 'スタッフが先に注文を受け付ける';

  @override
  String get setGuestOrdering => 'QRからの注文を許可';

  @override
  String get setStockDeduction => 'レシピに基づき在庫を減らす';

  @override
  String get setPaymentPolicy => 'お客様の支払いタイミング';

  @override
  String get policyPrepay => '調理前に支払い';

  @override
  String get policyPostpay => '食後に支払い';

  @override
  String get layoutList => 'リスト';

  @override
  String get layoutGrid => 'グリッド';

  @override
  String get layoutCompact => 'コンパクト';

  @override
  String get periodMonthly => '月額';

  @override
  String get periodYearly => '年額';

  @override
  String get healthCache => 'キャッシュ';

  @override
  String get healthEvents => '待機中のイベント';

  @override
  String get healthWebhooks => '失敗したWebhook';

  @override
  String get phone => '電話';

  @override
  String get notAvailable => '該当なし';

  @override
  String get plusTaxes => '税金はご注文時に計算されます';

  @override
  String get variants => 'バリエーション';

  @override
  String get addVariant => 'バリエーションを追加';

  @override
  String get addExtras => '追加オプションを追加';

  @override
  String get optionName => 'オプション名';

  @override
  String get uploadImage => '画像をアップロード';

  @override
  String get uploadLogo => 'ロゴをアップロード';

  @override
  String get uploadCover => 'カバーをアップロード';

  @override
  String get banners => 'バナー';

  @override
  String get bannerTitle => 'バナーのタイトル';

  @override
  String get branches => '店舗';

  @override
  String get addBranch => '店舗を追加';

  @override
  String get branchCode => '店舗コード';

  @override
  String get businessHours => '営業時間';

  @override
  String get opensAt => '開店';

  @override
  String get closesAt => '閉店';

  @override
  String get supportedLanguages => 'お客様向け言語';

  @override
  String get gatewaySetup => '決済ゲートウェイ';

  @override
  String get provider => 'プロバイダー';

  @override
  String get environment => 'モード';

  @override
  String get apiKeyId => 'APIキーID';

  @override
  String get apiKeySecret => 'APIシークレット';

  @override
  String get webhookSecret => 'Webhookシークレット';

  @override
  String get webhookUrl => 'Webhook URL(ゲートウェイに登録してください)';

  @override
  String get paymentMethods => '支払い方法';

  @override
  String get subscription => 'サブスクリプション';

  @override
  String get choosePlan => 'プランを選択';

  @override
  String get cancelSubscription => 'サブスクリプションを解約';

  @override
  String get splitBill => '伝票を分割';

  @override
  String get numberOfParts => '分割数';

  @override
  String get transferTable => 'テーブルを移動';

  @override
  String get recipe => 'レシピ';

  @override
  String get purchaseOrders => '発注';

  @override
  String get newPurchaseOrder => '新規発注';

  @override
  String get receiveGoods => '入荷処理';

  @override
  String get supplierInvoices => '仕入先請求書';

  @override
  String get invoiceNumber => '請求書番号';

  @override
  String get recordPayment => '支払いを記録';

  @override
  String get expiringStock => '期限間近の在庫';

  @override
  String get trialBalance => '試算表';

  @override
  String get debit => '借方';

  @override
  String get credit => '貸方';

  @override
  String get balanceSheet => '貸借対照表';

  @override
  String get assets => '資産';

  @override
  String get liabilities => '負債';

  @override
  String get equity => '純資産';

  @override
  String get journal => '仕訳帳';

  @override
  String get reverse => '取り消し';

  @override
  String get periods => '会計期間';

  @override
  String get closePeriod => '期間を締める';

  @override
  String get cashRegisters => 'レジ';

  @override
  String get openRegister => 'レジを開ける';

  @override
  String get closeRegister => 'レジを締める';

  @override
  String get openingFloat => '釣り銭準備金';

  @override
  String get countedCash => '実際の現金';

  @override
  String get expectedCash => '想定の現金';

  @override
  String get variance => '差額';

  @override
  String get payroll => '給与';

  @override
  String get grossPay => '総支給額';

  @override
  String get deductions => '控除';

  @override
  String get markPaid => '支払い済みにする';

  @override
  String get attendance => '勤怠';

  @override
  String get clockIn => '出勤';

  @override
  String get clockOut => '退勤';

  @override
  String get clockedIn => '完了';

  @override
  String get promotions => 'プロモーション';

  @override
  String get loyalty => 'ポイント';

  @override
  String get pointsPerUnit => '通貨単位あたりのポイント';

  @override
  String get valuePerPoint => '1ポイントの価値';

  @override
  String get reply => '返信';

  @override
  String get notifications => '通知';

  @override
  String get stations => 'キッチンステーション';

  @override
  String get routeToStation => 'ステーションに送る';

  @override
  String get users => 'ユーザー';

  @override
  String get disable => '無効化';

  @override
  String get translations => '翻訳';

  @override
  String get translationKey => 'キー';

  @override
  String get translationValue => 'テキスト';

  @override
  String get countries => '国';

  @override
  String get commissions => '手数料';

  @override
  String get announcements => 'お知らせ';

  @override
  String get bodyText => 'メッセージ本文';

  @override
  String get addresses => '保存済みの住所';

  @override
  String get addressLabel => 'ラベル';

  @override
  String get completedOrders => '完了した注文';

  @override
  String get chooseCafe => 'カフェを選択';

  @override
  String get reserveTable => 'テーブルを予約';

  @override
  String get tomorrow => '明日';

  @override
  String get payments => '支払い';

  @override
  String get refunds => '返金';

  @override
  String get settlements => '入金';

  @override
  String get syncSettlements => '入金を取得';

  @override
  String get paymentLink => '支払いリンク';

  @override
  String get createPaymentLink => '支払いリンクを作成';

  @override
  String get testConnection => '接続をテスト';

  @override
  String get connectionOk => '接続しました。オンライン決済が有効です。';

  @override
  String get connectionFailed => 'ゲートウェイがこのキーを拒否しました。';

  @override
  String get payPart => '一部を支払う';

  @override
  String get amountToPay => '支払う金額';

  @override
  String get paymentSuccessful => 'お支払いを受け付けました。ありがとうございます！';

  @override
  String get paymentNotCompleted => 'お支払いは完了しませんでした。今回の試行は請求されていません。';

  @override
  String get payOnline => 'オンラインで支払う';

  @override
  String get gatewayFee => 'ゲートウェイ手数料';

  @override
  String get referenceLabel => '参照番号';

  @override
  String get paymentBreakdown => '支払いの概要';

  @override
  String get approveRefund => '返金を承認';

  @override
  String get refundRequested => '返金を申請しました。マネージャーの承認が必要です。';

  @override
  String get reconciled => '照合済み';

  @override
  String get needsReview => '確認が必要';

  @override
  String get pendingKeys => '保存しました。接続をテストするとオンライン決済が有効になります。';

  @override
  String get openingCheckout => '安全な決済画面を開いています…';
}
