import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:warrantyreport/dummybloc.dart';

class DummyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dummy Page'),
      ),
      body: BlocProvider(
        create: (context) => DummyBloc()..add(FetchCustomersEvent()),
        child: DummyPageContent(),
      ),
    );
  }
}

class DummyPageContent extends StatefulWidget {
  @override
  _DummyPageContentState createState() => _DummyPageContentState();
}

class _DummyPageContentState extends State<DummyPageContent> {
  String? _selectedCustomerId;
  String? _selectedBillId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Customer Dropdown
          BlocBuilder<DummyBloc, DummyState>(
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

              // Deduplicate customers by ID to prevent dropdown errors
              final Map<String, dynamic> uniqueCustomers = {};
              for (var customer in state.customers) {
                uniqueCustomers[customer['id'].toString()] = customer;
              }
              final dedupedCustomers = uniqueCustomers.values.toList();

              // Validate if the selected customer ID still exists in the list
              final customerExists = dedupedCustomers.any(
                      (customer) => customer['id'].toString() == _selectedCustomerId);
              if (!customerExists) {
                _selectedCustomerId = null; // Reset if customer no longer exists
              }

              return DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedCustomerId,
                items: dedupedCustomers.map((customer) {
                  return DropdownMenuItem<String>(
                    value: customer['id'].toString(),
                    child: Text(customer['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCustomerId = value;
                      _selectedBillId = null; // Reset bill selection when customer changes
                    });
                    log('Selected Customer: $value');
                    context.read<DummyBloc>().add(FetchBillNumbersEvent(value));
                  }
                },
                hint: Text('Select Customer'),
              );
            },
          ),
          SizedBox(height: 24),

          // Bill No Dropdown
          BlocBuilder<DummyBloc, DummyState>(
            builder: (context, state) {
              if (_selectedCustomerId == null) {
                return Text('Please select a customer first');
              }

              if (state.isLoading) {
                return CircularProgressIndicator();
              }

              if (state.error != null) {
                return Text(
                  'Error: ${state.error}',
                  style: TextStyle(color: Colors.red),
                );
              }

              if (state.billNumbers.isEmpty) {
                return Text('No bills available for the selected customer');
              }

              // Deduplicate bill numbers by ID to prevent dropdown errors
              final Map<String, dynamic> uniqueBills = {};
              for (var bill in state.billNumbers) {
                uniqueBills[bill['id'].toString()] = bill;
              }
              final dedupedBills = uniqueBills.values.toList();

              // Validate if the selected bill ID still exists in the list
              final billExists = dedupedBills.any(
                      (bill) => bill['id'].toString() == _selectedBillId);
              if (!billExists) {
                _selectedBillId = null; // Reset if bill no longer exists
              }

              return DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedBillId,
                items: dedupedBills.map((bill) {
                  return DropdownMenuItem<String>(
                    value: bill['id'].toString(),
                    child: Text(bill['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedBillId = value;
                    });
                    log('Selected Bill Number: $value');
                  }
                },
                hint: Text('Select Bill No'),
              );
            },
          ),
        ],
      ),
    );
  }
}