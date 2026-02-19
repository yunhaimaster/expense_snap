import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 描述提取器（改進版）
///
/// 使用多種信號識別店名：
/// 1. 文字大小（bounding box 高度）
/// 2. 位置（頂部優先）
/// 3. 關鍵字匹配
/// 4. 文字特徵（中文/英文比例）
class DescriptionExtractor {
  DescriptionExtractor._();

  /// 店名關鍵字（擴充版）
  static final _storeKeywords = RegExp(
    // 餐飲
    r'餐廳|餐厅|茶餐廳|茶餐厅|酒樓|酒楼|飯店|饭店|食堂|'
    r'咖啡|Cafe|Coffee|麵包|面包|Bakery|麥當勞|麦当劳|肯德基|星巴克|'
    r'快餐|速食|燒味|烧味|粥|麵|面|茶|'
    // 零售
    r'店|商店|超市|便利店|7-?Eleven|OK便利|惠康|百佳|AEON|'
    r'商場|商场|百貨|百货|Mall|Plaza|Center|Centre|'
    r'市場|市场|街市|'
    // 公司
    r'公司|有限|Co\.|Ltd|Corp|Inc|'
    // 服務
    r'藥房|药房|診所|诊所|醫院|医院|理髮|理发|美容|'
    r'酒店|旅館|旅馆|Hotel|Motel|'
    // 交通
    r'的士|出租車|Taxi|Uber|港鐵|地鐵|巴士|'
    // 英文
    r'Restaurant|Store|Shop|Market|Mart|Express',
    caseSensitive: false,
  );

  /// 知名品牌（直接匹配，高信心度）
  static final _knownBrands = RegExp(
    // 快餐
    r"McDonald's?|麥當勞|麦当劳|KFC|肯德基|"
    r'Starbucks|星巴克|Pacific Coffee|'
    r'大家樂|大家乐|大快活|美心|Maxim|'
    r'吉野家|Yoshinoya|譚仔|谭仔|'
    // 便利店/超市
    r'7-?Eleven|7-?11|OK便利|Circle K|'
    r'惠康|Wellcome|百佳|PARKnSHOP|AEON|'
    r'萬寧|万宁|Mannings|屈臣氏|Watsons|'
    // 連鎖
    r'IKEA|宜家|Uniqlo|優衣庫|H&M|ZARA|'
    r'Apple|蘋果|Samsung|三星',
    caseSensitive: false,
  );

  /// 商品/服務關鍵字
  static final _itemKeywords = RegExp(
    r'午餐|晚餐|早餐|套餐|飲料|飲品|咖啡|奶茶|'
    r'車費|車票|機票|住宿|酒店|'
    r'文具|辦公|電腦|手機|'
    r'Lunch|Dinner|Breakfast|Meal|Coffee|Tea',
    caseSensitive: false,
  );

  /// 需要過濾的內容
  static final _filterPatterns = [
    // 地址
    RegExp(
      r'地址|Address|號$|号$|\d+樓|\d+楼|路$|街$|道$|大道|大廈|大厦',
      caseSensitive: false,
    ),
    // 電話
    RegExp(r'電話|电话|Tel|Phone|Fax|\d{8,}', caseSensitive: false),
    // 日期時間
    RegExp(r'\d{4}[-/年]\d{1,2}[-/月]|\d{1,2}:\d{2}'),
    // 收據編號
    RegExp(
      r'單號|单号|Invoice|Receipt|Order|訂單|编号|編號|No\.|#\d+',
      caseSensitive: false,
    ),
    // 金額相關
    RegExp(r'總計|总计|Total|Amount|小計|小计|合計|应付|應付|找續|找赎', caseSensitive: false),
    // 付款方式
    RegExp(
      r'現金|现金|Cash|信用卡|Credit|Visa|Master|八達通|支付寶|微信|Alipay|WeChat',
      caseSensitive: false,
    ),
    // 常見無意義內容
    RegExp(
      r'歡迎光臨|欢迎光临|謝謝|谢谢|Thank|Welcome|多謝|再見|再见|光臨|光临',
      caseSensitive: false,
    ),
    // 純數字行
    RegExp(r'^\d+$'),
    // 稅務相關
    RegExp(r'稅|税|VAT|GST', caseSensitive: false),
    // 網址
    RegExp(r'www\.|\.com|\.hk|http', caseSensitive: false),
    // 社交媒體
    RegExp(r'facebook|instagram|twitter|@', caseSensitive: false),
  ];

  /// 提取描述（店名或商品項目）
  static String? extract(RecognizedText text) {
    if (text.blocks.isEmpty) return null;

    // 排序區塊（按 Y 位置）
    final sortedBlocks = List<TextBlock>.from(text.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    // 第一輪：找知名品牌（任何位置）
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();
        if (_knownBrands.hasMatch(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
        }
      }
    }

    // 計算平均行高（用於識別大文字）
    double totalHeight = 0;
    int lineCount = 0;
    for (final block in sortedBlocks) {
      totalHeight += block.boundingBox.height;
      lineCount += block.lines.length;
    }
    final avgHeight = lineCount > 0 ? totalHeight / lineCount : 50.0;

    // 第二輪：找頂部區域的大文字或店名關鍵字
    for (var i = 0; i < sortedBlocks.length && i < 5; i++) {
      final block = sortedBlocks[i];
      final blockHeight = block.boundingBox.height / block.lines.length;
      final isLargeText = blockHeight > avgHeight * 1.2;

      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        // 優先選擇大文字或包含店名關鍵字的
        if (isLargeText || _storeKeywords.hasMatch(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
        }
      }
    }

    // 第三輪：找頂部有意義的文字
    for (var i = 0; i < sortedBlocks.length && i < 3; i++) {
      final block = sortedBlocks[i];

      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        if (_isLikelyStoreName(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
        }
      }
    }

    // 第四輪：找商品/服務項目
    for (final block in sortedBlocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (!_isValidCandidate(lineText)) continue;
        if (_shouldFilter(lineText)) continue;

        if (_itemKeywords.hasMatch(lineText)) {
          final cleaned = _cleanDescription(lineText);
          if (cleaned != null) return cleaned;
        }
      }
    }

    return null;
  }

  /// 檢查是否為有效候選
  static bool _isValidCandidate(String text) {
    return text.length >= 2 && text.length <= 50;
  }

  /// 檢查是否需要過濾
  static bool _shouldFilter(String text) {
    for (final pattern in _filterPatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// 判斷是否像店名
  static bool _isLikelyStoreName(String text) {
    // 數字佔比不超過 25%
    final digits = text.replaceAll(RegExp(r'[^\d]'), '').length;
    final ratio = digits / text.length;

    // 至少包含 2 個中文字或 4 個英文字母
    final hasChineseChars = RegExp(r'[\u4e00-\u9fa5]{2,}').hasMatch(text);
    final hasEnglishWords = RegExp(r'[a-zA-Z]{4,}').hasMatch(text);

    return ratio < 0.25 && (hasChineseChars || hasEnglishWords);
  }

  /// 清理描述文字
  static String? _cleanDescription(String text) {
    // 移除多餘空白和特殊符號
    var cleaned = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[*#\-_=\[\]]+|[*#\-_=\[\]]+$'), '')
        .trim();

    // 移除括號內的地址/電話
    cleaned = cleaned.replaceAll(RegExp(r'\([^)]*\d{6,}[^)]*\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'（[^）]*\d{6,}[^）]*）'), '');

    // 移除結尾的分店標識（保留核心名稱）
    cleaned = cleaned.replaceAll(
      RegExp(r'[\s\-]*分店$|[\s\-]*分行$|[\s\-]*門市$'),
      '',
    );

    // 驗證清理後的結果
    if (cleaned.length < 2) return null;

    // 限制長度
    if (cleaned.length > 30) {
      cleaned = '${cleaned.substring(0, 27)}...';
    }

    return cleaned.trim();
  }
}
