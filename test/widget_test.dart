import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expense_snap/main.dart';

void main() {
  testWidgets('App shows Phase 1 placeholder', (WidgetTester tester) async {
    // 建立 app 並觸發一幀
    await tester.pumpWidget(const ExpenseSnapApp());

    // 驗證 placeholder 頁面顯示
    expect(find.text('Expense Snap'), findsOneWidget);
    expect(find.text('Phase 1 完成'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long), findsOneWidget);
  });
}
