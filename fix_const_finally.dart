import 'dart:io';

void main() {
  var dataContent = File('lib/features/settings/presentation/pages/data_management_page.dart').readAsStringSync();
  dataContent = dataContent.replaceAll('const ListToCsvConverter()', 'ListToCsvConverter()');
  File('lib/features/settings/presentation/pages/data_management_page.dart').writeAsStringSync(dataContent);
}
