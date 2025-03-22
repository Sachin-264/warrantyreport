import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_html/js.dart';
import 'package:warrantyreport/Report/EditPages/EditBloc.dart';
import 'package:warrantyreport/Report/EditPages/editdetail_bloc.dart';
import 'package:warrantyreport/Report/Filter/filterbloc.dart';


import 'complaint_page.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<FilterBloc>(create: (context) => FilterBloc()),
            BlocProvider<EditBloc>(create: (context) => EditBloc()),
        BlocProvider<Editdetailbloc>(create: (context) => Editdetailbloc()),

  ],
      child: MyApp(),
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
