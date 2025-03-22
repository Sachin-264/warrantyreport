import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'editdetail_bloc.dart';

class EditPage extends StatelessWidget {
  final String userCode;
  final String companyCode;
  final String recNo;

  const EditPage({
    Key? key,
    required this.userCode,
    required this.companyCode,
    required this.recNo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Page'),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider<Editdetailbloc>(
            create: (context) => Editdetailbloc()
              ..add(FetchInitialDataEvent(
                userCode: userCode,
                companyCode: companyCode,
                recNo: recNo,
              )),
          ),
        ],
        child: const EditPageContent(),
      ),
    );
  }
}

class EditPageContent extends StatelessWidget {
  const EditPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const EditTopSection(),
          // Add other sections (EditMediumSection, EditBottomSection) here
        ],
      ),
    );
  }
}



class EditTopSection extends StatefulWidget {
  const EditTopSection({Key? key}) : super(key: key);

  @override
  _EditTopSectionState createState() => _EditTopSectionState();
}

class _EditTopSectionState extends State<EditTopSection> {
  final TextEditingController _customerController = TextEditingController();
  String? _selectedCustomerId;
  String? _selectedBillId;

  @override
  void initState() {
    super.initState();
    // Fetch customers when the widget is first loaded
    context.read<Editdetailbloc>().add(FetchCustomersEvent());
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  void _onCustomerSelected(String customerId) {
    setState(() {
      _selectedCustomerId = customerId;
      _selectedBillId = null; // Reset bill selection when customer changes
    });
    // Fetch bill numbers for the selected customer
    context.read<Editdetailbloc>().add(FetchBillNumbersEvent(customerId));
  }

  void _onBillSelected(String billId) {
    setState(() {
      _selectedBillId = billId;
    });
    // Fetch item details for the selected bill
    context.read<Editdetailbloc>().add(FetchItemDetailsEvent(billId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<Editdetailbloc, EditState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Search Field
              TextField(
                controller: _customerController,
                decoration: InputDecoration(
                  labelText: 'Search Customer',
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (query) {
                  // Debounce search to avoid frequent API calls
                  Future.delayed(const Duration(milliseconds: 500), () {
                    context.read<Editdetailbloc>().add(FetchCustomersEvent(query));
                  });
                },
              ),

              // Customer Dropdown
              if (state.customers.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedCustomerId,
                  items: state.customers.map((customer) {
                    return DropdownMenuItem<String>(
                      value: customer['id'],
                      child: Text(customer['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onCustomerSelected(value);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Customer',
                  ),
                ),

              // Bill Dropdown
              if (_selectedCustomerId != null && state.billNumbers.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedBillId,
                  items: state.billNumbers.map((bill) {
                    return DropdownMenuItem<String>(
                      value: bill['id'],
                      child: Text(bill['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _onBillSelected(value);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Select Bill',
                  ),
                ),

              // Loading Indicator
              if (state.isLoading) const CircularProgressIndicator(),

              // Error Message
              if (state.error != null)
                Text(
                  state.error!,
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        );
      },
    );
  }
}