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
  // Data from sections
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
        serviceDates: serviceDates,
      );

      if (response['status'] == 'success') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved successfully: ${response['message']}')),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: ${response['message']}')),
        );
      }
    } catch (e) {
      // Show exception message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // TopSection
          Card(
            margin: EdgeInsets.all(8),
            color: Colors.white,
            child: TopSection(
              onDataChanged: (data) {
                setState(() => topSectionData = data);
              },
            ),
          ),

          // MediumSection
          Card(
            margin: EdgeInsets.all(8),
            color: Colors.white,
            child: MediumSection(
              onDataChanged: (itemsData, dates) {
                setState(() {
                  mediumSectionData = itemsData;
                  serviceDates = dates.cast<DateTime>();
                });
              },
            ),
          ),

          // BottomSection
          Card(
            margin: EdgeInsets.all(8),
            color: Colors.white,
            child: BottomSection(
              onDataChanged: (data) {
                setState(() => bottomSectionData = data);
              },
            ),
          ),

          // Save Button
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
          onPressed: () {},
          style: _buttonStyle(Colors.red),
          child: _buttonText("Cancel"),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {
            final remarks = bottomSectionData['remarks'] ?? '';
            final items = mediumSectionData['items'] ?? [];
            final dates = serviceDates;

            // Print or send data
            print('Top Section Data: $topSectionData');
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

    // Fetch initial data
    log('Fetching initial data...');
    context.read<FilterBloc>().add(FetchSlipNoEvent());
    context.read<FilterBloc>().add(FetchHeadquartersEvent());
    context.read<FilterBloc>().add(FetchCustomersEvent());
  }

  void _updateData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<FilterBloc>().state;
      widget.onDataChanged({
        'slipNo': state.data['slipNo']?[0]['NextCode'] ?? '',
        'hqCode': _selectedHeadquarter ?? '',
        'entryDate': _dateController.text,
      });
    });
  }

  @override
  void dispose() {
    _dateController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Slip No Fields
          Row(
            children: [
              // Date Picker
              Text(
                'Date:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
                        Text(
                          _dateController.text,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        Icon(Icons.calendar_today, size: 16, color: Colors.blue[900]),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),

              // Slip No
              Text(
                'Slip No:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: BlocSelector<FilterBloc, FilterState, String>(
                  selector: (state) => state.data['slipNo']?[0]['NextCode'] ?? '',
                  builder: (context, slipNo) {
                    return Text(
                      slipNo,
                      style: GoogleFonts.poppins(fontSize: 14),
                    );
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Headquarters Dropdown
          Row(
            children: [
              Text(
                'Headquarters:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: BlocSelector<FilterBloc, FilterState, List<Map<String, String>>>(
                  selector: (state) => state.data['headquarters'] ?? [],
                  builder: (context, headquarters) {
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

          // Customer Dropdown
          // Customer Autocomplete Field
          Row(
            children: [
              Text(
                'Customer:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: BlocBuilder<FilterBloc, FilterState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return CircularProgressIndicator();
                    }
                    if (state.error != null) {
                      return Text(
                        'Error: ${state.error}',
                        style: TextStyle(color: Colors.red),
                      );
                    }

                    // Deduplicate customers by ID
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
                          return customerName.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                              customerId.contains(textEditingValue.text);
                        }).cast<Map<String, dynamic>>();
                      },
                      displayStringForOption: (option) => option['name'] ?? '',
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        // If we have a selected customer, display its name in the field
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
                                maxWidth: MediaQuery.of(context).size.width - 60, // Adjust width as needed
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

          // Bill No Dropdown
          Row(
            children: [
              Text(
                'Bill No:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: BlocBuilder<FilterBloc, FilterState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return CircularProgressIndicator();
                    }
                    // if (state.error != null) {
                    //   return Text(
                    //     'Error: ${state.error}',
                    //     style: TextStyle(color: Colors.red),
                    //   );
                    // }
                    if (state.billNumbers.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey), // Add border
                          borderRadius: BorderRadius.circular(10), // Add rounded corners
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Add padding
                        child: Text(
                          'No bills available for the selected customer',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
                      value: null,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}