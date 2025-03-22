import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Filter/Customapi.dart';

class EditEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchInitialDataEvent extends EditEvent {
  final String userCode;
  final String companyCode;
  final String recNo;

  FetchInitialDataEvent({
    required this.userCode,
    required this.companyCode,
    required this.recNo,
  });

  @override
  List<Object?> get props => [userCode, companyCode, recNo];
}

class FetchCustomersEvent extends EditEvent {}

class FetchBillNumbersEvent extends EditEvent {
  final String customerId;
  FetchBillNumbersEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class FetchItemDetailsEvent extends EditEvent {
  final String billNumber;
  FetchItemDetailsEvent(this.billNumber);

  @override
  List<Object?> get props => [billNumber];
}

class ResetFormEvent extends EditEvent {}

class EditState extends Equatable {
  final bool isLoading;
  final bool isItemDetailsLoading;
  final List<Map<String, String>> customers;
  final List<Map<String, String>> billNumbers;
  final List<Map<String, dynamic>> itemDetails;
  final String? error;
  final Map<String, dynamic> initialData;

  const EditState({
    this.isLoading = false,
    this.isItemDetailsLoading = false,
    this.customers = const [],
    this.billNumbers = const [],
    this.itemDetails = const [],
    this.error,
    this.initialData = const {},
  });

  EditState copyWith({
    bool? isLoading,
    bool? isItemDetailsLoading,
    List<Map<String, String>>? customers,
    List<Map<String, String>>? billNumbers,
    List<Map<String, dynamic>>? itemDetails,
    String? error,
    Map<String, dynamic>? initialData,
  }) {
    return EditState(
      isLoading: isLoading ?? this.isLoading,
      isItemDetailsLoading: isItemDetailsLoading ?? this.isItemDetailsLoading,
      customers: customers ?? this.customers,
      billNumbers: billNumbers ?? this.billNumbers,
      itemDetails: itemDetails ?? this.itemDetails,
      error: error ?? this.error,
      initialData: initialData ?? this.initialData,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isItemDetailsLoading,
    customers,
    billNumbers,
    itemDetails,
    error,
    initialData,
  ];
}
class Editdetailbloc extends Bloc<EditEvent, EditState> {
  Editdetailbloc() : super(const EditState()) {
    on<FetchInitialDataEvent>(_fetchInitialData);
    on<FetchCustomersEvent>(_fetchCustomers);
    on<FetchBillNumbersEvent>(_fetchBillNumbers);
    on<FetchItemDetailsEvent>(_fetchItemDetails);
  }

  Future<void> _fetchInitialData(FetchInitialDataEvent event, Emitter<EditState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final url = 'http://localhost/sp_LoadWarrantyAMCMaster.php?UserCode=${event.userCode}&CompanyCode=${event.companyCode}&RecNo=${event.recNo}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        emit(state.copyWith(
          isLoading: false,
          initialData: data,
        ));
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch initial data'));
    }
  }

  Future<void> _fetchCustomers(FetchCustomersEvent event, Emitter<EditState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final customers = await FilterApiService.fetchCustomers(event.query);
      emit(state.copyWith(customers: customers, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch customers'));
    }
  }

  Future<void> _fetchBillNumbers(FetchBillNumbersEvent event, Emitter<EditState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final billNumbers = await FilterApiService.fetchBillNumbers(event.customerId);
      emit(state.copyWith(billNumbers: billNumbers, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch bill numbers'));
    }
  }

  Future<void> _fetchItemDetails(FetchItemDetailsEvent event, Emitter<EditState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final itemDetails = await FilterApiService.getItemDetails(event.billNumber);
      emit(state.copyWith(itemDetails: itemDetails, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch item details'));
    }
  }
}}