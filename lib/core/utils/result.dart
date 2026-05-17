import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

typedef Result<T> = Either<Failure, T>;
typedef FutureResult<T> = Future<Either<Failure, T>>;
