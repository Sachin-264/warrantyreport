import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_html/js.dart';
import 'package:warrantyreport/Report/EditPages/EditBloc.dart';
import 'package:warrantyreport/Report/EditPages/EditDetails/EditFilterbloc.dart';
import 'package:warrantyreport/Report/Filter/filterbloc.dart';

import 'Report/EditPages/EditDetails/EditFilter.dart';
import 'complaint_page.dart';

void main() {
  // Suppress layout-related errors in debug mode
  if (!kReleaseMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('Each child must be laid out exactly once')) {
        return; // Suppress this specific error
      }
      FlutterError.presentError(details);
    };
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<FilterBloc>(create: (context) => FilterBloc()),
        BlocProvider<EditBloc>(create: (context) => EditBloc()),
        BlocProvider<EditFilterBloc>(create: (context) => EditFilterBloc()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Complaint Entry App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ComplaintPage(),
    );
  }
}
