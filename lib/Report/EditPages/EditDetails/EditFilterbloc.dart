import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../Filter/Customapi.dart';


// Events
abstract class EditFilterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadWarrantyDataEvent extends EditFilterEvent {
  final String userCode;
  final String companyCode;
  final String recNo;

  LoadWarrantyDataEvent({
    required this.userCode,
    required this.companyCode,
    required this.recNo,
  });

  @override
  List<Object?> get props => [userCode, companyCode, recNo];
}

class FetchSlipNoEvent extends EditFilterEvent {}
class FetchHeadquartersEvent extends EditFilterEvent {}
class FetchCustomersEvent extends EditFilterEvent {}
class FetchBillNumbersEvent extends EditFilterEvent {
  final String customerId;
  FetchBillNumbersEvent(this.customerId);
  @override
  List<Object?> get props => [customerId];
}
class FetchItemDetailsEvent extends EditFilterEvent {
  final String billNumber;
  FetchItemDetailsEvent(this.billNumber);
  @override
  List<Object?> get props => [billNumber];
}
class ResetFormEvent extends EditFilterEvent {}

// States
class EditFilterState extends Equatable {
  final bool isLoading;
  final bool isSlipNoLoading;
  final bool isHeadquartersLoading;
  final bool isItemDetailsLoading;
  final List<Map<String, String>> customers;
  final List<Map<String, String>> billNumbers;
  final List<Map<String, dynamic>> itemDetails;
  final String? error;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? warrantyData;

  const EditFilterState({
    this.isLoading = false,
    this.isSlipNoLoading = false,
    this.isHeadquartersLoading = false,
    this.isItemDetailsLoading = false,
    this.customers = const [],
    this.billNumbers = const [],
    this.itemDetails = const [],
    this.error,
    this.data = const {},
    this.warrantyData,
  });

  EditFilterState copyWith({
    bool? isLoading,
    bool? isSlipNoLoading,
    bool? isHeadquartersLoading,
    bool? isItemDetailsLoading,
    List<Map<String, String>>? customers,
    List<Map<String, String>>? billNumbers,
    List<Map<String, dynamic>>? itemDetails,
    String? error,
    Map<String, dynamic>? data,
    Map<String, dynamic>? warrantyData,
  }) {
    return EditFilterState(
      isLoading: isLoading ?? this.isLoading,
      isSlipNoLoading: isSlipNoLoading ?? this.isSlipNoLoading,
      isHeadquartersLoading: isHeadquartersLoading ?? this.isHeadquartersLoading,
      isItemDetailsLoading: isItemDetailsLoading ?? this.isItemDetailsLoading,
      customers: customers ?? this.customers,
      billNumbers: billNumbers ?? this.billNumbers,
      itemDetails: itemDetails ?? this.itemDetails,
      error: error ?? this.error,
      data: data ?? this.data,
      warrantyData: warrantyData ?? this.warrantyData,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSlipNoLoading,
    isHeadquartersLoading,
    isItemDetailsLoading,
    customers,
    billNumbers,
    itemDetails,
    error,
    data,
    warrantyData,
  ];
}

// Bloc
class EditFilterBloc extends Bloc<EditFilterEvent, EditFilterState> {
  EditFilterBloc() : super(const EditFilterState()) {
    on<LoadWarrantyDataEvent>(_loadWarrantyData);
    on<FetchSlipNoEvent>(_fetchSlipNo);
    on<FetchHeadquartersEvent>(_fetchHeadquarters);
    on<FetchCustomersEvent>(_fetchCustomers);
    on<FetchBillNumbersEvent>(_fetchBillNumbers);
    on<FetchItemDetailsEvent>(_fetchItemDetails);
    on<ResetFormEvent>(_resetForm);
  }

  Future<void> _loadWarrantyData(LoadWarrantyDataEvent event, Emitter<EditFilterState> emit) async {
    log('Handling LoadWarrantyDataEvent');
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final warrantyData = await FilterApiService.loadWarrantyData(
        userCode: event.userCode,
        companyCode: event.companyCode,
        recNo: event.recNo,
      );
      log('Warranty Data Loaded: $warrantyData');
      emit(state.copyWith(
        isLoading: false,
        warrantyData: warrantyData,
        error: null,
      ));
    } catch (e) {
      log('Error in _loadWarrantyData: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load warranty data: $e',
        warrantyData: null,
      ));
    }
  }

  Future<void> _fetchSlipNo(FetchSlipNoEvent event, Emitter<EditFilterState> emit) async {
    emit(state.copyWith(isSlipNoLoading: true));
    try {
      final slipNo = await FilterApiService.fetchSlipNo();
      final newData = Map<String, dynamic>.from(state.data)..['slipNo'] = slipNo;
      emit(state.copyWith(isSlipNoLoading: false, data: newData));
    } catch (e) {
      emit(state.copyWith(isSlipNoLoading: false, error: 'Failed to fetch SlipNo: $e'));
    }
  }

  Future<void> _fetchHeadquarters(FetchHeadquartersEvent event, Emitter<EditFilterState> emit) async {
    emit(state.copyWith(isHeadquartersLoading: true));
    try {
      final headquarters = await FilterApiService.fetchHeadquarters();
      final newData = Map<String, dynamic>.from(state.data)..['headquarters'] = headquarters;
      emit(state.copyWith(isHeadquartersLoading: false, data: newData));
    } catch (e) {
      emit(state.copyWith(isHeadquartersLoading: false, error: 'Failed to fetch Headquarters: $e'));
    }
  }

  Future<void> _fetchCustomers(FetchCustomersEvent event, Emitter<EditFilterState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final customers = await FilterApiService.fetchCustomers();
      emit(state.copyWith(customers: customers, isLoading: false));
    } catch (e) {
      log('Error fetching customers: $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch customers'));
    }
  }

  Future<void> _fetchBillNumbers(FetchBillNumbersEvent event, Emitter<EditFilterState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final billNumbers = await FilterApiService.fetchBillNumbers(event.customerId);
      log('Fetched Bill Numbers: $billNumbers');
      emit(state.copyWith(billNumbers: billNumbers, isLoading: false));
    } catch (e) {
      log('Error fetching bill numbers: $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch bill numbers'));
    }
  }

  Future<void> _fetchItemDetails(FetchItemDetailsEvent event, Emitter<EditFilterState> emit) async {
    log('Fetching Item Details for Bill Number: ${event.billNumber}');
    emit(state.copyWith(isItemDetailsLoading: true, error: null));
    try {
      final itemDetails = await FilterApiService.getItemDetails(event.billNumber);
      log('Item Details Fetched: $itemDetails');
      emit(state.copyWith(itemDetails: itemDetails, isItemDetailsLoading: false));
    } catch (e) {
      log('Error fetching item details: $e', error: e);
      emit(state.copyWith(isItemDetailsLoading: false, error: 'Failed to fetch item details'));
    }
  }
  Future<void> _resetForm(ResetFormEvent event, Emitter<EditFilterState> emit) async {
    emit(const EditFilterState());
    add(FetchSlipNoEvent());
    add(FetchHeadquartersEvent());
    add(FetchCustomersEvent());
  }
}