import 'package:disclosure_app_fl/bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group("bloc", () {
    test("can instance", () {
      final bloc = AppBloc();

      expect(bloc, isNot(null));
    });

    test("initial value is null", () async {
      final bloc = AppBloc();
      final data = await bloc.disclosure$.first;
      expect(data, null);
    });
  });
}
