import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:warrantyreport/Report/Filter/filterbloc.dart';

class BottomSection extends StatefulWidget {
  final Function(Map<String, String>) onDataChanged;

  const BottomSection({Key? key, required this.onDataChanged}) : super(key: key);

  @override
  _BottomSectionState createState() => _BottomSectionState();
}

class _BottomSectionState extends State<BottomSection> with AutomaticKeepAliveClientMixin {
  final TextEditingController _remarksController = TextEditingController();
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _remarksController.addListener(_onRemarksChanged);
  }

  void _resetFields() {
    setState(() {
      _remarksController.clear();
    });
    widget.onDataChanged({'remarks': ''});
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
    return BlocListener<FilterBloc, FilterState>(
      listener: (context, state) {
        if (!state.isLoading && state.billNumbers.isEmpty && state.itemDetails.isEmpty) {
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
          ],
        ),
      ),
    );
  }
}