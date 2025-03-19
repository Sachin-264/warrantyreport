import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:warrantyreport/Report/Filter/BottomSection.dart';
import 'package:warrantyreport/Report/Filter/MediumSection.dart';
import 'Customapi.dart';
import 'filterbloc.dart';

class FilterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Filter Page',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[900],
        actions: [
          BlocBuilder<FilterBloc, FilterState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<FilterBloc>(
            create: (context) => FilterBloc(),
          ),
        ],
        child: FilterPageContent(),
      ),
    );
  }
}

class FilterPageContent extends StatefulWidget {
  @override
  _FilterPageContentState createState() => _FilterPageContentState();
}

class _FilterPageContentState extends State<FilterPageContent> {
  Map<String, String> topSectionData = {};
  Map<String, dynamic> mediumSectionData = {};
  Map<String, String> bottomSectionData = {};
  List<DateTime> serviceDates = [];

  Future<void> _sendDataToApi() async {
    try {
      final response = await FilterApiService.saveWarrantyData(
        topSectionData: topSectionData,
        mediumSectionData: mediumSectionData,
        bottomSectionData: bottomSectionData,
      );

      if (response['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved successfully: ${response['message']}')),
        );
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: ${response['message']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending data: $e')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      topSectionData = {};
      mediumSectionData = {};
      bottomSectionData = {};
      serviceDates = [];
    });
    context.read<FilterBloc>().add(ResetFormEvent());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            margin: EdgeInsets.all(8),
            color: Colors.white,
            child: TopSection(
              onDataChanged: (data) {
                setState(() => topSectionData = data);
              },
            ),
          ),
          Card(
            margin: EdgeInsets.all(8),
            color: Colors.white,
            child: MediumSection(
              onDataChanged: (itemsData) {
                setState(() {
                  mediumSectionData = itemsData;
                });
              },
            ),
          ),
          Card(
            margin: EdgeInsets.all(8),
            color: Colors.white,
            child: BottomSection(
              onDataChanged: (data) {
                setState(() => bottomSectionData = data);
              },
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _resetForm,
          style: _buttonStyle(Colors.red),
          child: _buttonText("Cancel"),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            final remarks = bottomSectionData['remarks'] ?? '';
            final items = mediumSectionData['items'] ?? [];
            final dates = serviceDates;

            print('Top Section Data: $topSectionData');
            print('Medium Section Data: $mediumSectionData');
            print('Remarks: $remarks');
            print('Items: $items');
            print('Dates: $dates');

            _sendDataToApi();
          },
          style: _buttonStyle(Colors.green),
          child: _buttonText("Save"),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {},
          style: _buttonStyle(Colors.blue),
          child: _buttonText("Edit"),
        ),
      ],
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

class TopSection extends StatefulWidget {
  final Function(Map<String, String>) onDataChanged;

  TopSection({required this.onDataChanged});

  @override
  _TopSectionState createState() => _TopSectionState();
}

class _TopSectionState extends State<TopSection> {
  final TextEditingController _dateController = TextEditingController();
  String? _selectedHeadquarter;
  String? _selectedCustomerId;
  String? _selectedBillId;
  final TextEditingController _customerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    log('Fetching initial data...');
    context.read<FilterBloc>().add(FetchSlipNoEvent());
    context.read<FilterBloc>().add(FetchHeadquartersEvent());
    context.read<FilterBloc>().add(FetchCustomersEvent());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<FilterBloc>().state;
      if (state.data['headquarters']?.isNotEmpty ?? false) {
        setState(() {
          _selectedHeadquarter = state.data['headquarters'][0]['id'];
        });
        _updateData();
      }
    });
  }

  void _updateData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<FilterBloc>().state;
      widget.onDataChanged({
        'slipNo': state.data['slipNo']?[0]['NextCode'] ?? '',
        'hqCode': _selectedHeadquarter ?? '',
        'entryDate': _dateController.text,
        'InvoiceRecNo': _selectedBillId ?? '',
        'accountCode': _selectedCustomerId ?? '',
      });
    });
  }

  void _resetFields() {
    setState(() {
      _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _selectedHeadquarter = null; // Will be set to default by build
      _selectedCustomerId = null;
      _selectedBillId = null;
      _customerController.clear();
    });
    _updateData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      _updateData();
    }
  }

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
        error ?? 'Failed to load customers. Please try again.',
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.red[700],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FilterBloc, FilterState>(
      listener: (context, state) {
        if (!state.isLoading && state.billNumbers.isEmpty && state.itemDetails.isEmpty) {
          _resetFields();
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Date:',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_dateController.text, style: GoogleFonts.poppins(fontSize: 14)),
                          Icon(Icons.calendar_today, size: 16, color: Colors.blue[900]),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Slip No:',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: BlocSelector<FilterBloc, FilterState, String>(
                    selector: (state) => state.data['slipNo']?[0]['NextCode'] ?? '',
                    builder: (context, slipNo) {
                      return Text(slipNo, style: GoogleFonts.poppins(fontSize: 14));
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Headquarters:',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: BlocSelector<FilterBloc, FilterState, List<Map<String, String>>>(
                    selector: (state) => state.data['headquarters'] ?? [],
                    builder: (context, headquarters) {
                      if (headquarters.isNotEmpty && _selectedHeadquarter == null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedHeadquarter = headquarters[0]['id'];
                          });
                          _updateData();
                        });
                      }
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedHeadquarter,
                        items: headquarters.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'],
                            child: Text(item['name'] ?? '', style: GoogleFonts.poppins()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedHeadquarter = value);
                          _updateData();
                        },
                        hint: Text('Select Headquarters', style: GoogleFonts.poppins()),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        dropdownColor: Colors.white,
                        menuMaxHeight: 200,
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Customer:',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: BlocBuilder<FilterBloc, FilterState>(
                    builder: (context, state) {
                      if (state.isLoading && state.customers.isEmpty) {
                        return _buildLoader();
                      }
                      if (state.error != null && state.customers.isEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildErrorMessage(state.error),
                            TextFormField(
                              controller: _customerController,
                              decoration: InputDecoration(
                                labelText: 'Search Customer (Manual Entry)',
                                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: Icon(Icons.search),
                                suffixIcon: _customerController.text.isNotEmpty
                                    ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _customerController.clear();
                                    setState(() {
                                      _selectedCustomerId = null;
                                      _selectedBillId = null;
                                    });
                                  },
                                )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCustomerId = null;
                                });
                              },
                            ),
                          ],
                        );
                      }
                      final Map<String, dynamic> uniqueCustomers = {};
                      for (var customer in state.customers) {
                        uniqueCustomers[customer['id'].toString()] = customer;
                      }
                      final dedupedCustomers = uniqueCustomers.values.toList();

                      return RawAutocomplete<Map<String, dynamic>>(
                        textEditingController: _customerController,
                        focusNode: FocusNode(),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return dedupedCustomers.cast<Map<String, dynamic>>();
                          }
                          return dedupedCustomers.where((customer) {
                            final customerName = customer['name'] ?? '';
                            final customerId = customer['id'].toString();
                            return customerName
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()) ||
                                customerId.contains(textEditingValue.text);
                          }).cast<Map<String, dynamic>>();
                        },
                        displayStringForOption: (option) => option['name'] ?? '',
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          if (_selectedCustomerId != null && textEditingController.text.isEmpty) {
                            final selectedCustomer = dedupedCustomers.firstWhere(
                                  (customer) => customer['id'].toString() == _selectedCustomerId,
                              orElse: () => {'name': ''},
                            );
                            textEditingController.text = selectedCustomer['name'] ?? '';
                          }
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Search Customer',
                              labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: textEditingController.text.isNotEmpty
                                  ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  textEditingController.clear();
                                  setState(() {
                                    _selectedCustomerId = null;
                                    _selectedBillId = null;
                                  });
                                },
                              )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                            ),
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
                                    itemBuilder: (BuildContext context, int index) {
                                      final option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(
                                          option['name'] ?? '',
                                          style: GoogleFonts.poppins(fontSize: 14),
                                        ),
                                        subtitle: Text(
                                          'ID: ${option['id']}',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                        onTap: () {
                                          onSelected(option);
                                          final customerId = option['id'].toString();
                                          setState(() {
                                            _selectedCustomerId = customerId;
                                            _selectedBillId = null;
                                            _customerController.text = option['name'] ?? '';
                                          });
                                          log('Selected Customer: $customerId');
                                          context.read<FilterBloc>().add(FetchBillNumbersEvent(customerId));
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
            SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Bill No:',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: BlocBuilder<FilterBloc, FilterState>(
                    builder: (context, state) {
                      if (state.isLoading && state.billNumbers.isEmpty) {
                        return _buildLoader();
                      }
                      if (state.billNumbers.isEmpty) {
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Text(
                            'No bills available for the selected customer',
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        items: state.billNumbers.map((bill) {
                          return DropdownMenuItem<String>(
                            value: bill['id'],
                            child: Text(bill['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          log('Selected Bill Number: $value');
                          setState(() {
                            _selectedBillId = value;
                          });
                          _updateData();
                          if (value != null) {
                            context.read<FilterBloc>().add(FetchItemDetailsEvent(value));
                          }
                        },
                        hint: Text('Select Bill No.', style: GoogleFonts.poppins()),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        dropdownColor: Colors.white,
                        menuMaxHeight: 400,
                        value: _selectedBillId,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}