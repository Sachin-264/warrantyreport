import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'editfilterbloc.dart';

class EditTopSection extends StatefulWidget {
  final Function(Map<String, String>) onDataChanged;

  const EditTopSection({required this.onDataChanged, Key? key}) : super(key: key);

  @override
  _EditTopSectionState createState() => _EditTopSectionState();
}

class _EditTopSectionState extends State<EditTopSection> {
  // Field variables
  String _complaintDate = '';
  String _slipNo = '';
  String _hqName = '';
  String? _selectedCustomerId;
  String? _selectedBillId;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _slipNoController = TextEditingController();
  final TextEditingController _hqNameController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<EditFilterBloc>().add(FetchCustomersEvent());
  }

  void _updateData() {
    final state = context.read<EditFilterBloc>().state;
    String billNo = '';
    String billDate = '';

    if (_selectedBillId != null && state.billNumbers.isNotEmpty) {
      final selectedBill = state.billNumbers.firstWhere(
            (bill) => bill['id'] == _selectedBillId,
        orElse: () => {'name': '', 'BillDate': ''},
      );
      billNo = selectedBill['name'] ?? '';
      billDate = selectedBill['BillDate'] ?? '';
    }

    widget.onDataChanged({
      'entryDate': _complaintDate,
      'slipNo': _slipNo,
      'hqName': _hqName,
      'InvoiceRecNo': _selectedBillId ?? '',
      'accountCode': _selectedCustomerId ?? '',
      'BillNo': billNo,
      'BillDate': billDate,
      'accountName': _customerController.text,
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
    _slipNoController.dispose();
    _hqNameController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _complaintDate.isNotEmpty
          ? DateFormat('dd-MMM-yyyy').parseLoose(_complaintDate)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _complaintDate = DateFormat('dd-MMM-yyyy').format(picked);
        _dateController.text = _complaintDate;
      });
      _updateData();
    }
  }

  // Common UI Components
  Widget _buildLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[900]!),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String? error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        error ?? 'Failed to load data. Please try again.',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.red[700]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditFilterBloc, EditFilterState>(
      listener: (context, state) {
        if (state.warrantyData != null && state.warrantyData!['topSection'] != null) {
          final topSection = state.warrantyData!['topSection'];
          setState(() {
            _complaintDate = topSection['ComplaintDate']?.toString() ?? '';
            _slipNo = topSection['SlipNo']?.toString() ?? '';
            _hqName = topSection['HQName']?.toString() ?? '';
            _dateController.text = _complaintDate;
            _slipNoController.text = _slipNo;
            _hqNameController.text = _hqName;
          });
          _updateData();
        } else if (state.error != null) {
          setState(() {
            _complaintDate = '';
            _slipNo = '';
            _hqName = '';
            _dateController.clear();
            _slipNoController.clear();
            _hqNameController.clear();
          });
          _updateData();
        }
      },
      builder: (context, state) {
        if (state.isLoading) return _buildLoader();
        if (state.error != null) return _buildErrorMessage(state.error);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Slip No Row
              Row(
                children: [
                  Text(
                    'Date:',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateController.text.isEmpty ? 'Select Date' : _dateController.text,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: _dateController.text.isEmpty ? Colors.grey[600] : Colors.black,
                              ),
                            ),
                            Icon(Icons.calendar_today, size: 16, color: Colors.blue[900]),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Slip No:',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _slipNoController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Enter Slip No',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      onChanged: (value) {
                        setState(() => _slipNo = value);
                        _updateData();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Headquarters Row
              Row(
                children: [
                  Text(
                    'Headquarters:',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _hqNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Enter Headquarters',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      onChanged: (value) {
                        setState(() => _hqName = value);
                        _updateData();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Customer Row
              Row(
                children: [
                  Text(
                    'Customer:',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BlocBuilder<EditFilterBloc, EditFilterState>(
                      builder: (context, state) {
                        if (state.isLoading && state.customers.isEmpty) return _buildLoader();
                        if (state.error != null && state.customers.isEmpty) {
                          return TextFormField(
                            controller: _customerController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              hintText: 'Enter Customer (Manual)',
                              hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              suffixIcon: _customerController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _customerController.clear();
                                  setState(() {
                                    _selectedCustomerId = null;
                                    _selectedBillId = null;
                                  });
                                  _updateData();
                                },
                              )
                                  : null,
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                            onChanged: (value) {
                              setState(() => _selectedCustomerId = null);
                              _updateData();
                            },
                          );
                        }
                        final uniqueCustomers = <String, Map<String, dynamic>>{};
                        for (var customer in state.customers) {
                          uniqueCustomers[customer['id']!] = customer;
                        }
                        final dedupedCustomers = uniqueCustomers.values.toList();

                        return RawAutocomplete<Map<String, dynamic>>(
                          textEditingController: _customerController,
                          focusNode: FocusNode(),
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text.isEmpty) {
                              return dedupedCustomers;
                            }
                            return dedupedCustomers.where((customer) {
                              final customerName = customer['name']?.toLowerCase() ?? '';
                              final customerId = customer['id']?.toLowerCase() ?? '';
                              final query = textEditingValue.text.toLowerCase();
                              return customerName.contains(query) || customerId.contains(query);
                            });
                          },
                          displayStringForOption: (option) => option['name'] ?? '',
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                hintText: 'Search Customer',
                                hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: controller.text.isNotEmpty
                                    ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    controller.clear();
                                    setState(() {
                                      _selectedCustomerId = null;
                                      _selectedBillId = null;
                                    });
                                    _updateData();
                                  },
                                )
                                    : null,
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                              onFieldSubmitted: (value) => onFieldSubmitted(),
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: 200,
                                    maxWidth: MediaQuery.of(context).size.width - 60,
                                  ),
                                  child: Container(
                                    color: Colors.white,
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(option['name'] ?? '', style: GoogleFonts.poppins(fontSize: 14)),
                                          subtitle: Text(
                                            'ID: ${option['id']}',
                                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                          onTap: () {
                                            onSelected(option);
                                            setState(() {
                                              _selectedCustomerId = option['id'];
                                              _selectedBillId = null;
                                              _customerController.text = option['name'] ?? '';
                                            });
                                            _updateData();
                                            context.read<EditFilterBloc>().add(FetchBillNumbersEvent(_selectedCustomerId!));
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bill No Row
              Row(
                children: [
                  Text(
                    'Bill No:',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BlocBuilder<EditFilterBloc, EditFilterState>(
                      builder: (context, state) {
                        if (state.isLoading && state.billNumbers.isEmpty) return _buildLoader();
                        if (state.billNumbers.isEmpty) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            child: Text(
                              'No bills available',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedBillId,
                          items: state.billNumbers.map((bill) {
                            return DropdownMenuItem<String>(
                              value: bill['id'],
                              child: Text(bill['name'] ?? '', style: GoogleFonts.poppins(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedBillId = value);
                            _updateData();
                            if (value != null) {
                              context.read<EditFilterBloc>().add(FetchItemDetailsEvent(value));
                            }
                          },
                          hint: Text('Select Bill No.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                          dropdownColor: Colors.white,
                          menuMaxHeight: 400,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}