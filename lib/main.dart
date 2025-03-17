import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:warrantyreport/Report/Filter/filterbloc.dart';
import 'package:warrantyreport/Report/Filter/TopSection.dart';
import 'package:warrantyreport/Report/Warranty/BlocWarranty.dart';
import 'package:warrantyreport/Report/Warranty/Warranty.dart';
import 'package:warrantyreport/dummybloc.dart';
import 'package:warrantyreport/dummypage.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    // Ignore ParentDataWidget errors (or log them elsewhere)
    if (!details.exceptionAsString().contains('ParentDataWidget')) {
      FlutterError.dumpErrorToConsole(details);
    }
  };
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<DummyBloc>(
            create: (context) => DummyBloc(),
          ),
          BlocProvider<FilterBloc>(
            create: (context) => FilterBloc(),
          ),
          BlocProvider<WarrantyBloc>(
            create: (context) =>  WarrantyBloc(),
          ),
        ],
        child: FilterPage(),
      ),
    );
  }
}
