import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'editfilterbloc.dart';

class EditBottomSection extends StatefulWidget {
  final Function(Map<String, String>) onDataChanged;

  const EditBottomSection({Key? key, required this.onDataChanged}) : super(key: key);

  @override
  EditBottomSectionState createState() => EditBottomSectionState(); // Make the state class public
}

class EditBottomSectionState extends State<EditBottomSection> with AutomaticKeepAliveClientMixin {
  final TextEditingController _remarksController = TextEditingController();
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();


    _remarksController.addListener(_onRemarksChanged);

    // Listen to the state changes in the bloc
    context.read<EditFilterBloc>().stream.listen((state) {


      if (state.warrantyData != null && state.warrantyData!['topSection'] != null) {

        // Set the remarks from the loaded warranty data
        setState(() {
          _remarksController.text = state.warrantyData!['topSection']['Remarks'] ?? '';

        });
      } else {

      }
    });
  }

  void _resetFields() {

    setState(() {
      _remarksController.clear();
    });
    widget.onDataChanged({'remarks': ''});
  }

  // Public method to clear fields
  void clearFields() {
    _resetFields();
  }

  @override
  void dispose() {

    _remarksController.removeListener(_onRemarksChanged);
    _remarksController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onRemarksChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      widget.onDataChanged({'remarks': _remarksController.text});
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<EditFilterBloc, EditFilterState>(
      listener: (context, state) {
        // Only reset fields if warrantyData is null or empty
        if (!state.isLoading && state.warrantyData == null) {

          _resetFields();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remarks',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter remarks...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            // const SizedBox(height: 10),
            // ElevatedButton(
            //   onPressed: _resetFields,
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.red,
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //     minimumSize: const Size(100, 45),
            //   ),
            //   child: Text(
            //     'Cancel',
            //     style: GoogleFonts.poppins(
            //       color: Colors.white,
            //       fontSize: 16,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}