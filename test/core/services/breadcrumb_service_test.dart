import 'package:expense_snap/core/services/breadcrumb_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreadcrumbType', () {
    test('應有 5 種類型', () {
      expect(BreadcrumbType.values.length, equals(5));
    });
  });

  group('Breadcrumb', () {
    test('建構函式應正確設定必要欄位', () {
      final timestamp = DateTime.now();
      final breadcrumb = Breadcrumb(
        type: BreadcrumbType.userAction,
        message: 'Test action',
        timestamp: timestamp,
      );

      expect(breadcrumb.type, equals(BreadcrumbType.userAction));
      expect(breadcrumb.message, equals('Test action'));
      expect(breadcrumb.timestamp, equals(timestamp));
      expect(breadcrumb.category, isNull);
      expect(breadcrumb.data, isNull);
    });

    test('建構函式應正確設定選用欄位', () {
      final breadcrumb = Breadcrumb(
        type: BreadcrumbType.userAction,
        message: 'Test',
        timestamp: DateTime.now(),
        category: 'button',
        data: {'buttonId': 'submit'},
      );

      expect(breadcrumb.category, equals('button'));
      expect(breadcrumb.data, equals({'buttonId': 'submit'}));
    });

    group('工廠方法', () {
      test('userAction 應建立正確的麵包屑', () {
        final crumb = Breadcrumb.userAction(
          'Clicked save',
          category: 'button',
          data: {'screen': 'add_expense'},
        );

        expect(crumb.type, equals(BreadcrumbType.userAction));
        expect(crumb.message, equals('Clicked save'));
        expect(crumb.category, equals('button'));
        expect(crumb.data, equals({'screen': 'add_expense'}));
      });

      test('navigation 應建立正確的麵包屑', () {
        final crumb = Breadcrumb.navigation(
          '/expense/123',
          params: {'id': '123'},
        );

        expect(crumb.type, equals(BreadcrumbType.navigation));
        expect(crumb.message, contains('/expense/123'));
        expect(crumb.category, equals('navigation'));
        expect(crumb.data, equals({'id': '123'}));
      });

      test('network 應建立正確的麵包屑', () {
        final crumb = Breadcrumb.network(
          'GET',
          'https://api.example.com/rates',
          statusCode: 200,
          success: true,
        );

        expect(crumb.type, equals(BreadcrumbType.network));
        expect(crumb.message, equals('GET https://api.example.com/rates'));
        expect(crumb.category, equals('network'));
        expect(crumb.data, containsPair('statusCode', 200));
        expect(crumb.data, containsPair('success', true));
      });

      test('error 應建立正確的麵包屑', () {
        final crumb = Breadcrumb.error(
          'Database connection failed',
          errorType: 'DatabaseException',
        );

        expect(crumb.type, equals(BreadcrumbType.error));
        expect(crumb.message, equals('Database connection failed'));
        expect(crumb.category, equals('DatabaseException'));
      });
    });

    group('toJson', () {
      test('應包含必要欄位', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
        final crumb = Breadcrumb(
          type: BreadcrumbType.userAction,
          message: 'Test',
          timestamp: timestamp,
        );

        final json = crumb.toJson();

        expect(json['type'], equals('userAction'));
        expect(json['message'], equals('Test'));
        expect(json['timestamp'], equals('2024-01-15T10:30:00.000'));
        expect(json.containsKey('category'), isFalse);
        expect(json.containsKey('data'), isFalse);
      });

      test('應包含選用欄位（若有設定）', () {
        final crumb = Breadcrumb(
          type: BreadcrumbType.userAction,
          message: 'Test',
          timestamp: DateTime.now(),
          category: 'test',
          data: {'key': 'value'},
        );

        final json = crumb.toJson();

        expect(json['category'], equals('test'));
        expect(json['data'], equals({'key': 'value'}));
      });

      test('空 data 不應包含在 JSON 中', () {
        final crumb = Breadcrumb(
          type: BreadcrumbType.userAction,
          message: 'Test',
          timestamp: DateTime.now(),
          data: {},
        );

        final json = crumb.toJson();
        expect(json.containsKey('data'), isFalse);
      });
    });

    test('toString 應正確格式化', () {
      final timestamp = DateTime(2024, 1, 15, 10, 30, 0);
      final crumb = Breadcrumb(
        type: BreadcrumbType.userAction,
        message: 'Clicked button',
        timestamp: timestamp,
        category: 'UI',
      );

      final str = crumb.toString();

      expect(str, contains('2024-01-15T10:30:00.000'));
      expect(str, contains('[userAction]'));
      expect(str, contains('(UI)'));
      expect(str, contains('Clicked button'));
    });
  });

  group('BreadcrumbService', () {
    late BreadcrumbService service;

    setUp(() {
      // 使用 singleton 但清除狀態
      service = BreadcrumbService.instance;
      service.clear();
    });

    tearDown(() {
      service.clear();
    });

    test('初始狀態應為空', () {
      expect(service.count, equals(0));
      expect(service.breadcrumbs, isEmpty);
    });

    test('add 應正確新增麵包屑', () {
      final crumb = Breadcrumb.userAction('Test action');
      service.add(crumb);

      expect(service.count, equals(1));
      expect(service.breadcrumbs.first, equals(crumb));
    });

    test('應限制最多 10 個麵包屑', () {
      // 新增 12 個麵包屑
      for (var i = 0; i < 12; i++) {
        service.add(Breadcrumb.userAction('Action $i'));
      }

      expect(service.count, equals(BreadcrumbService.maxBreadcrumbs));
      // 最舊的應該被移除
      expect(
        service.breadcrumbs.first.message,
        equals('Action 2'),
      );
      expect(
        service.breadcrumbs.last.message,
        equals('Action 11'),
      );
    });

    test('addUserAction 應正確新增', () {
      service.addUserAction('Click save', category: 'button');

      expect(service.count, equals(1));
      final crumb = service.breadcrumbs.first;
      expect(crumb.type, equals(BreadcrumbType.userAction));
      expect(crumb.message, equals('Click save'));
      expect(crumb.category, equals('button'));
    });

    test('addNavigation 應正確新增', () {
      service.addNavigation('/home', params: {'tab': 'expenses'});

      expect(service.count, equals(1));
      final crumb = service.breadcrumbs.first;
      expect(crumb.type, equals(BreadcrumbType.navigation));
      expect(crumb.message, contains('/home'));
    });

    test('addNetwork 應正確新增', () {
      service.addNetwork('GET', 'https://api.test.com', statusCode: 200);

      expect(service.count, equals(1));
      final crumb = service.breadcrumbs.first;
      expect(crumb.type, equals(BreadcrumbType.network));
    });

    test('addError 應正確新增', () {
      service.addError('Something went wrong', errorType: 'RuntimeError');

      expect(service.count, equals(1));
      final crumb = service.breadcrumbs.first;
      expect(crumb.type, equals(BreadcrumbType.error));
      expect(crumb.category, equals('RuntimeError'));
    });

    test('clear 應清除所有麵包屑', () {
      service.addUserAction('Action 1');
      service.addUserAction('Action 2');
      expect(service.count, equals(2));

      service.clear();
      expect(service.count, equals(0));
    });

    test('breadcrumbs 應返回唯讀列表', () {
      service.addUserAction('Test');
      final list = service.breadcrumbs;

      // 嘗試修改應該失敗
      expect(() => list.add(Breadcrumb.userAction('Hack')), throwsA(anything));
    });

    test('getReport 空列表應返回提示訊息', () {
      final report = service.getReport();
      expect(report, contains('No breadcrumbs'));
    });

    test('getReport 應包含所有麵包屑', () {
      service.addUserAction('Action 1');
      service.addNavigation('/home');
      service.addError('Error occurred');

      final report = service.getReport();

      expect(report, contains('Breadcrumb Trail'));
      expect(report, contains('3 entries'));
      expect(report, contains('Action 1'));
      expect(report, contains('/home'));
      expect(report, contains('Error occurred'));
    });

    test('toJsonList 應返回 JSON 格式列表', () {
      service.addUserAction('Test');
      service.addNavigation('/test');

      final jsonList = service.toJsonList();

      expect(jsonList.length, equals(2));
      expect(jsonList[0]['type'], equals('userAction'));
      expect(jsonList[1]['type'], equals('navigation'));
    });
  });

  group('全域訪問點', () {
    test('breadcrumbs 應返回 singleton', () {
      expect(breadcrumbs, same(BreadcrumbService.instance));
    });
  });
}
