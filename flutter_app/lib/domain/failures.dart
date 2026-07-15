enum FailureCategory { dataIntegrity, storage, navigation, rendering, unknown }

sealed class GaussFailure implements Exception {
  const GaussFailure({
    required this.code,
    required this.category,
    required this.operation,
    required this.retryable,
    required this.safeMessage,
    required this.cause,
  });

  final String code;
  final FailureCategory category;
  final String operation;
  final bool retryable;
  final String safeMessage;
  final Object cause;

  @override
  String toString() => '$runtimeType($code, $operation)';
}

final class StartupFailure extends GaussFailure {
  const StartupFailure(Object cause)
    : super(
        code: 'STARTUP_LOCAL_STATE_UNAVAILABLE',
        category: FailureCategory.storage,
        operation: 'initialize_app',
        retryable: true,
        safeMessage:
            'The offline archive or local progress store could not be opened safely.',
        cause: cause,
      );
}

final class MissionLoadFailure extends GaussFailure {
  const MissionLoadFailure(Object cause)
    : super(
        code: 'MISSION_ARCHIVE_LOAD_FAILED',
        category: FailureCategory.dataIntegrity,
        operation: 'load_mission',
        retryable: true,
        safeMessage:
            'The offline archive could not open this mission. Saved progress is unchanged.',
        cause: cause,
      );
}

final class MissionWriteFailure extends GaussFailure {
  const MissionWriteFailure(Object cause, {required super.operation})
    : super(
        code: 'MISSION_LOCAL_WRITE_FAILED',
        category: FailureCategory.storage,
        retryable: true,
        safeMessage:
            'This mission step could not be saved. The current answer remains on screen.',
        cause: cause,
      );
}
