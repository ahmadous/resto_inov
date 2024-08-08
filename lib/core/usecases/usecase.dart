// lib/core/usecases/usecase.dart
import 'package:dartz/dartz.dart';
import 'package:resto_inov/core/error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// lib/core/usecases/usecase.dart
class NoParams {}
