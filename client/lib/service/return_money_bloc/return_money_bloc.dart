import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'package:udharo/data/repository/borrow_repository.dart';

part 'return_money_event.dart';
part 'return_money_state.dart';

class ReturnMoneyBloc extends Bloc<ReturnMoneyEvent, ReturnMoneyState> {
  final BorrowRepository _borrowRepository;

  ReturnMoneyBloc(this._borrowRepository) : super(ReturnMoneyStateInitial()) {
    on<ReturnMoneyEventMakeReturnRequest>(
      (event, emit) async {
        try{
          await _borrowRepository.returnMoney(
            event.borrowId,
            event.amount,
          );
          emit(ReturnMoneyStateSuccess());
        }on Exception catch(e){
          emit(ReturnMoneyStateError(e.toString()));
        }
      },
    );
    on<ReturnMoneyEventMakeKhaltiPayment>(
      (event, emit) async {
        try {
          // make payment
          await KhaltiScope.of(event.context).pay(
            config: PaymentConfig(
              amount: event.amount * 100,

              // // for testing
              // amount: 20 * 100,

              productIdentity: event.productIdentity,
              productName: event.productName,
            ),
            preferences: [
              PaymentPreference.khalti,
            ],
            onSuccess: (success) {
              emit(ReturnMoneyStateKhaltiPaymentSuccess(success: success));
              // print('Success: ${success.token}');
            },
            onFailure: (failure) {
              emit(ReturnMoneyStateError(failure.message));
            },
          );
        } on Exception catch (e) {
          emit(ReturnMoneyStateError(e.toString()));
        }
      },
    );
  }
}
