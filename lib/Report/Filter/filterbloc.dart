import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:warrantyreport/Report/Filter/Customapi.dart';

// Events
abstract class FilterEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchSlipNoEvent extends FilterEvent {}

class FetchHeadquartersEvent extends FilterEvent {}

class FetchCustomersEvent extends FilterEvent {}

class FetchBillNumbersEvent extends FilterEvent {
  final String customerId;
  FetchBillNumbersEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class FetchItemDetailsEvent extends FilterEvent {
  final String billNumber;
  FetchItemDetailsEvent(this.billNumber);

  @override
  List<Object?> get props => [billNumber];
}

class ResetFormEvent extends FilterEvent {}

// States
class FilterState extends Equatable {
  final bool isLoading;
  final bool isSlipNoLoading;
  final bool isHeadquartersLoading;
  final bool isItemDetailsLoading;
  final List<Map<String, String>> customers;
  final List<Map<String, String>> billNumbers;
  final List<Map<String, dynamic>> itemDetails;
  final String? error;
  final Map<String, dynamic> data;

  const FilterState({
    this.isLoading = false,
    this.isSlipNoLoading = false,
    this.isHeadquartersLoading = false,
    this.isItemDetailsLoading = false,
    this.customers = const [],
    this.billNumbers = const [],
    this.itemDetails = const [],
    this.error,
    this.data = const {},
  });

  FilterState copyWith({
    bool? isLoading,
    bool? isSlipNoLoading,
    bool? isHeadquartersLoading,
    bool? isItemDetailsLoading,
    List<Map<String, String>>? customers,
    List<Map<String, String>>? billNumbers,
    List<Map<String, dynamic>>? itemDetails,
    String? error,
    Map<String, dynamic>? data,
  }) {
    return FilterState(
      isLoading: isLoading ?? this.isLoading,
      isSlipNoLoading: isSlipNoLoading ?? this.isSlipNoLoading,
      isHeadquartersLoading: isHeadquartersLoading ?? this.isHeadquartersLoading,
      isItemDetailsLoading: isItemDetailsLoading ?? this.isItemDetailsLoading,
      customers: customers ?? this.customers,
      billNumbers: billNumbers ?? this.billNumbers,
      itemDetails: itemDetails ?? this.itemDetails,
      error: error ?? this.error,
      data: data ?? this.data,
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
  ];
}

// Bloc
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc() : super(const FilterState()) {
    on<FetchSlipNoEvent>(_fetchSlipNo);
    on<FetchHeadquartersEvent>(_fetchHeadquarters);
    on<FetchCustomersEvent>(_fetchCustomers);
    on<FetchBillNumbersEvent>(_fetchBillNumbers);
    on<FetchItemDetailsEvent>(_fetchItemDetails);
    on<ResetFormEvent>(_resetForm);
  }

  Future<void> _fetchSlipNo(FetchSlipNoEvent event, Emitter<FilterState> emit) async {
    emit(state.copyWith(isSlipNoLoading: true));
    try {
      final slipNo = await FilterApiService.fetchSlipNo();
      final newData = Map<String, dynamic>.from(state.data)..['slipNo'] = slipNo;
      emit(state.copyWith(isSlipNoLoading: false, data: newData));
    } catch (e) {
      emit(state.copyWith(isSlipNoLoading: false, error: 'Failed to fetch SlipNo: $e'));
    }
  }

  Future<void> _fetchHeadquarters(FetchHeadquartersEvent event, Emitter<FilterState> emit) async {
    emit(state.copyWith(isHeadquartersLoading: true));
    try {
      final headquarters = await FilterApiService.fetchHeadquarters();
      final newData = Map<String, dynamic>.from(state.data)..['headquarters'] = headquarters;
      emit(state.copyWith(isHeadquartersLoading: false, data: newData));
    } catch (e) {
      emit(state.copyWith(isHeadquartersLoading: false, error: 'Failed to fetch Headquarters: $e'));
    }
  }

  Future<void> _fetchCustomers(FetchCustomersEvent event, Emitter<FilterState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final customers = await FilterApiService.fetchCustomers();
      emit(state.copyWith(customers: customers, isLoading: false));
    } catch (e) {
      log('Error fetching customers: $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch customers'));
    }
  }

  Future<void> _fetchBillNumbers(FetchBillNumbersEvent event, Emitter<FilterState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final billNumbers = await FilterApiService.fetchBillNumbers(event.customerId);
      log('Fetched Bill Numbers: $billNumbers');
      if (billNumbers != state.billNumbers) {
        emit(state.copyWith(billNumbers: billNumbers, isLoading: false));
      }
    } catch (e) {
      log('Error fetching bill numbers: $e');
      emit(state.copyWith(isLoading: false, error: 'Failed to fetch bill numbers'));
    }
  }

  Future<void> _fetchItemDetails(FetchItemDetailsEvent event, Emitter<FilterState> emit) async {
    emit(state.copyWith(isItemDetailsLoading: true, error: null));
    try {
      final itemDetails = await FilterApiService.getItemDetails(event.billNumber);
      log('Fetched Item Details: $itemDetails');
      if (itemDetails != state.itemDetails) {
        emit(state.copyWith(itemDetails: itemDetails, isItemDetailsLoading: false));
      }
    } catch (e) {
      log('Error fetching item details: $e');
      emit(state.copyWith(isItemDetailsLoading: false, error: 'Failed to fetch item details'));
    }
  }

  Future<void> _resetForm(ResetFormEvent event, Emitter<FilterState> emit) async {
    emit(const FilterState()); // Reset to initial state
    add(FetchSlipNoEvent());
    add(FetchHeadquartersEvent());
    add(FetchCustomersEvent());
  }
}