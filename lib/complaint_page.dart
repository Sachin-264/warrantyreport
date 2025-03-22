import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:excel/excel.dart'; // For Excel export
import 'package:pdf/pdf.dart'; // For PDF export
import 'package:pdf/widgets.dart' as pw; // For PDF export
import 'package:path_provider/path_provider.dart'; // For file storage
import 'dart:io'; // For file operations
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ignore: depend_on_referenced_packages
import 'package:universal_html/html.dart' as html;
import 'package:warrantyreport/Report/EditPages/EditBloc.dart';
import 'package:warrantyreport/Report/EditPages/EditUI.dart';
import 'package:warrantyreport/Report/Filter/TopSection.dart';
import 'package:warrantyreport/Report/Filter/filterbloc.dart';



class ComplaintPage extends StatelessWidget {
  ComplaintPage();

  ListTile _createDrawerItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Icon(icon),
          Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(text),
          )
        ],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "Complaint Entry List",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue,
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
        drawer: Drawer(
          child: Container(
            color: Colors.blue[50],
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, size: 50, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          'Complaint Management',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _createDrawerItem(
                  icon: Icons.home,
                  text: 'Complaint Page',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
    _createDrawerItem(
    icon: Icons.edit,
    text: 'Edit Warrany ACM',
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BlocProvider.value(
                  value: context.read<EditBloc>(),
                  child: EditUI(),
                ),
          )
      );
    },
    ),
                _createDrawerItem(
                  icon: Icons.edit,
                  text: 'Warrany ACM',
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<FilterBloc>(),
                            child: FilterPage(),
                          ),
                        )
                    );
                  },
                ),
                Divider(),
                _createDrawerItem(
                  icon: Icons.settings,
                  text: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        body: Center(
          child: Text('Complaint Page'),
        ));
  }
}
