import 'package:flutter_test/flutter_test.dart';
import 'package:yapp/core/constants/app_constants.dart';

void main() {
  test('app name is configured', () {
    expect(AppConstants.appName, 'Yapp');
  });
}
