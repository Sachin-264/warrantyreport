import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Filter/Customapi.dart';
import 'editbottom.dart';
import 'editmedium.dart';
import 'edittop.dart';
import 'editfilterbloc.dart';

class EditFilterPage extends StatelessWidget {
  final String userCode;
  final String companyCode;
  final String recNo;

  const EditFilterPage({
    required this.userCode,
    required this.companyCode,
    required this.recNo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditFilterBloc>(
      create: (context) => EditFilterBloc()
        ..add(LoadWarrantyDataEvent(
          userCode: userCode,
          companyCode: companyCode,
          recNo: recNo,
        )),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Edit Warranty',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.blue[900],
          actions: [
            BlocBuilder<EditFilterBloc, EditFilterState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: EditFilterPageContent(
          userCode: userCode,
          companyCode: companyCode,
          recNo: recNo,
        ),
      ),
    );
  }
}

class EditFilterPageContent extends StatefulWidget {
  final String userCode;
  final String companyCode;
  final String recNo;

  const EditFilterPageContent({
    required this.userCode,
    required this.companyCode,
    required this.recNo,
    Key? key,
  }) : super(key: key);

  @override
  _EditFilterPageContentState createState() => _EditFilterPageContentState();
}

class _EditFilterPageContentState extends State<EditFilterPageContent> {
  Map<String, dynamic> topSectionData = {};
  Map<String, dynamic> mediumSectionData = {};
  Map<String, String> bottomSectionData = {};

  final GlobalKey<EditBottomSectionState> _editBottomSectionKey = GlobalKey();

  Future<void> _sendDataToApi() async {
    try {
      topSectionData['userCode'] = widget.userCode;
      topSectionData['companyCode'] = widget.companyCode;
      topSectionData['recNo'] = widget.recNo;

      log('Top Section Data for API: $topSectionData');
      log('Medium Section Data: $mediumSectionData');
      log('Bottom Section Data: $bottomSectionData');

      final response = await FilterApiService.editSaveWarrantyData(
        topSectionData: topSectionData,
        mediumSectionData: mediumSectionData,
        bottomSectionData: bottomSectionData,
      );

      log('API Response: $response');

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data updated successfully: ${response['message']}')),
        );

        Navigator.pop(context, true); // Navigate back with success flag
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update data: ${response['message']}')),
        );
      }
    } catch (e) {
      log('Error in _sendDataToApi: $e', stackTrace: StackTrace.current);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating data: $e')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      topSectionData = {
        'userCode': widget.userCode,
        'companyCode': widget.companyCode,
        'recNo': widget.recNo,
      };
      mediumSectionData = {};
      bottomSectionData = {};
    });
    context.read<EditFilterBloc>().add(ResetFormEvent());
    log('Form Reset - Top Section Data: $topSectionData');
  }

  @override
  void initState() {
    super.initState();
    topSectionData = {
      'userCode': widget.userCode,
      'companyCode': widget.companyCode,
      'recNo': widget.recNo,
    };
    log('Initial Top Section Data: $topSectionData');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.white,
            child: EditTopSection(
              onDataChanged: (data) {
                setState(() {
                  topSectionData = {
                    'userCode': widget.userCode,
                    'companyCode': widget.companyCode,
                    'recNo': widget.recNo,
                    ...data,
                  };
                });
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.white,
            child: EditMediumSection(
              onDataChanged: (itemsData) {
                setState(() {
                  mediumSectionData = itemsData;
                });
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.all(8),
            color: Colors.white,
            child: EditBottomSection(
              key: _editBottomSectionKey,
              onDataChanged: (data) {
                setState(() {
                  bottomSectionData = data;
                });
              },
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _resetForm,
            style: _buttonStyle(Colors.red),
            child: _buttonText("Cancel"),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _sendDataToApi,
            style: _buttonStyle(Colors.green),
            child: _buttonText("Update"),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              _editBottomSectionKey.currentState?.clearFields();
            },
            style: _buttonStyle(Colors.orange),
            child: _buttonText("Clear Bottom"),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      minimumSize: const Size(100, 45),
    );
  }

  Widget _buttonText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}