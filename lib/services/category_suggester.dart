import '../core/constants/expense_category.dart';

/// 分類建議服務
///
/// 根據描述文字自動建議支出分類
/// 使用關鍵字匹配，優先長關鍵字（更具體）
class CategorySuggester {
  /// 根據文字建議分類
  ///
  /// 使用優先級匹配：
  /// 1. 先嘗試長關鍵字（≥3 字元，更具體）
  /// 2. 短關鍵字優先級較低
  /// 3. 若無匹配返回 null
  ExpenseCategory? suggestFromText(String? text) {
    if (text == null || text.isEmpty) return null;

    final lowerText = text.toLowerCase();

    // 第一輪：長關鍵字匹配（≥3 字元，更具體）
    for (final entry in _longKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    // 第二輪：短關鍵字匹配（可能有誤判）
    for (final entry in _shortKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return entry.key;
        }
      }
    }

    return null;
  }

  /// 長關鍵字（優先匹配，較具體）
  static const _longKeywords = <ExpenseCategory, List<String>>{
    ExpenseCategory.meals: [
      // 中文
      '餐廳', '餐飲', '咖啡', '早餐', '午餐', '晚餐', '宵夜', '飲料', '茶餐廳', '快餐', '外賣', '美食',
      // 品牌
      '大家樂', '美心', '麥當勞', '肯德基', '星巴克', '太興', '翠華', '譚仔', '吉野家', '元氣',
      // 英文
      'cafe', 'restaurant', 'dining', 'breakfast', 'lunch', 'dinner', 'food',
      'mcdonald', 'starbucks', 'kfc', 'subway', 'pizza',
    ],
    ExpenseCategory.transport: [
      // 中文
      '的士', '計程車', '港鐵', '地鐵', '巴士', '小巴', '停車', '泊車', '油站', '加油', '火車', '高鐵',
      '機場快線', '渡輪', '船票', '車費', '車資', '交通',
      // 品牌/服務
      'uber', 'grab', 'didi', 'taxi', 'mtr',
      // 英文
      'parking', 'petrol', 'gas station', 'bus', 'ferry', 'train', 'airport express',
    ],
    ExpenseCategory.accommodation: [
      // 中文
      '酒店', '旅館', '民宿', '住宿', '旅店', '飯店', '賓館', '房費',
      // 品牌/服務
      'airbnb', 'booking', 'agoda', 'hotels',
      // 英文
      'hotel', 'hostel', 'lodging', 'accommodation', 'motel', 'resort',
    ],
    ExpenseCategory.officeSupplies: [
      // 中文
      '文具', '辦公', '影印', '打印', '列印', '複印', '碳粉', '墨水', '紙張', '筆記本', '辦公用品',
      // 英文
      'office', 'stationery', 'printing', 'paper', 'supplies',
    ],
    ExpenseCategory.communication: [
      // 中文
      '電話費', '話費', '上網費', '數據', '寬頻', '流量', '月費', '手機', '電訊', '通訊',
      // 品牌
      '中國移動', '香港電訊', 'csl', 'smartone', '3hk',
      // 英文
      'data plan', 'mobile plan', 'broadband', 'internet', 'phone bill', 'telecom',
    ],
    ExpenseCategory.entertainment: [
      // 中文
      '電影', '戲院', '遊戲', '演唱會', '展覽', '娛樂', '門票', '入場費', '音樂會', '表演', '主題樂園',
      // 品牌
      '迪士尼', '海洋公園', 'netflix', 'spotify',
      // 英文
      'cinema', 'movie', 'game', 'concert', 'exhibition', 'entertainment', 'ticket', 'show',
    ],
    ExpenseCategory.medical: [
      // 中文
      '醫院', '診所', '藥房', '醫療', '看診', '掛號', '藥費', '體檢', '牙醫', '眼科', '門診',
      // 英文
      'clinic', 'pharmacy', 'hospital', 'medical', 'doctor', 'dental', 'health',
    ],
  };

  /// 短關鍵字（較寬鬆，可能有誤判）
  /// 注意：避免過短的字如「餐」「食」，容易誤判
  static const _shortKeywords = <ExpenseCategory, List<String>>{
    ExpenseCategory.meals: ['茶', '麵', '飯'],
    ExpenseCategory.communication: ['sim'],
    ExpenseCategory.medical: ['藥'],
  };
}
