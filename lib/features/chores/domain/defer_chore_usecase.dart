import 'package:hearth/features/chores/domain/chore_models.dart';

class DeferChoreUseCase {
  const DeferChoreUseCase();

  ChoreEntity execute({
    required ChoreEntity chore,
    required DateTime newDueAt,
  }) {
    return chore.copyWith(nextDueAt: newDueAt);
  }
}
