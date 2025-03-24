import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'EditBloc.dart';
import 'EditDetails/EditFilter.dart';

class EditUI extends StatelessWidget {
  const EditUI({Key? key}) : super(key: key);

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[900]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formattedDate = "${picked.day.toString().padLeft(2, '0')}-${_getMonthName(picked.month)}-${picked.year}";
      if (isFromDate) {
        context.read<EditBloc>().add(FromDateChanged(formattedDate));
      } else {
        context.read<EditBloc>().add(ToDateChanged(formattedDate));
      }
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EditBloc(),
      child: BlocListener<EditBloc, EditState>(
        listener: (context, state) {
          if (state.message.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: state.isError ? Colors.red : Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.blue[900],
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Edit AMC Report',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: BlocBuilder<EditBloc, EditState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    readOnly: true,
                                    controller: TextEditingController(text: state.fromDate),
                                    decoration: InputDecoration(
                                      labelText: 'From Date',
                                      labelStyle: GoogleFonts.poppins(),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: const Icon(Icons.calendar_today),
                                    ),
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    readOnly: true,
                                    controller: TextEditingController(text: state.toDate),
                                    decoration: InputDecoration(
                                      labelText: 'To Date',
                                      labelStyle: GoogleFonts.poppins(),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      suffixIcon: const Icon(Icons.calendar_today),
                                    ),
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => context.read<EditBloc>().add(ResetEvent()),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Reset', style: GoogleFonts.poppins(color: Colors.white)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.close, color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[900],
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => context.read<EditBloc>().add(SubmitEvent()),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Show', style: GoogleFonts.poppins(color: Colors.white)),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BlocBuilder<EditBloc, EditState>(
                    builder: (context, state) {
                      if (state.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state.data.isEmpty) {
                        return Center(
                          child: Text(
                            'No data available',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        );
                      }
                      return Card(
                        elevation: 6,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 32,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 20,
                                  dataRowHeight: 60,
                                  headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                                  columns: [
                                    DataColumn(
                                      label: Text('SNo', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    ),
                                    DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          'ItemName',
                                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text('Action', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  rows: state.data.map((item) {
                                    return DataRow(cells: [
                                      DataCell(
                                        Text(item['SNo'] ?? '', style: GoogleFonts.poppins()),
                                      ),
                                      DataCell(
                                        Text(
                                          item['ItemName'] ?? '',
                                          style: GoogleFonts.poppins(),
                                          softWrap: true,
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.blue[900],
                                              ),
                                              onPressed: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                        EditFilterPage(
                                                          userCode: '1',
                                                          companyCode: '101',
                                                          recNo: item['RecNo'],
                                                        ),
                                                    transitionsBuilder:
                                                        (context, animation, secondaryAnimation, child) {
                                                      const begin = Offset(1.0, 0.0);
                                                      const end = Offset.zero;
                                                      const curve = Curves.easeInOut;
                                                      var tween = Tween(begin: begin, end: end)
                                                          .chain(CurveTween(curve: curve));
                                                      return SlideTransition(
                                                        position: animation.drive(tween),
                                                        child: child,
                                                      );
                                                    },
                                                  ),
                                                );

                                                if (result == true) {
                                                  context.read<EditBloc>().add(SubmitEvent());
                                                }
                                              },
                                              child: Text('Edit', style: GoogleFonts.poppins()),
                                            ),
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              onPressed: () => context.read<EditBloc>().add(DeleteEvent(item['RecNo'])),
                                              child: Text('Delete', style: GoogleFonts.poppins()),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}