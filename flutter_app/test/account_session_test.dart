import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gauss/auth/gauss_account_session.dart';
import 'package:gauss/data/local/gauss_database.dart';
import 'package:gauss/data/question_bank_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('account storage keys are stable, opaque, and account-distinct', () {
    const idA = '00000000-0000-4000-8000-000000000001';
    const idB = '00000000-0000-4000-8000-000000000002';
    final keyA = GaussAccountSession.storageKeyFor(idA);
    final keyB = GaussAccountSession.storageKeyFor(idB);

    expect(keyA, hasLength(24));
    expect(keyA, matches(RegExp(r'^[0-9a-f]{24}$')));
    expect(keyA, GaussAccountSession.storageKeyFor(idA));
    expect(keyA, isNot(keyB));
    expect(keyA, isNot(contains(idA)));
  });

  test('closing one account session cannot close or expose another', () async {
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    addTearDown(
      () => drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
    );
    final databaseA = GaussDatabase(NativeDatabase.memory());
    final databaseB = GaussDatabase(NativeDatabase.memory());
    final sessionA = await GaussAccountSession.open(
      '00000000-0000-4000-8000-000000000001',
      databaseOverride: databaseA,
      questionBankOverride: QuestionBankRepository(),
    );
    final sessionB = await GaussAccountSession.open(
      '00000000-0000-4000-8000-000000000002',
      databaseOverride: databaseB,
      questionBankOverride: QuestionBankRepository(),
    );

    await databaseA
        .into(databaseA.appFlags)
        .insert(
          AppFlagsCompanion.insert(key: 'owner', value: 'a', updatedAt: 1),
        );
    await databaseB
        .into(databaseB.appFlags)
        .insert(
          AppFlagsCompanion.insert(key: 'owner', value: 'b', updatedAt: 1),
        );
    expect(
      await (databaseA.select(databaseA.appFlags)
            ..where((row) => row.key.equals('owner')))
          .map((row) => row.value)
          .getSingle(),
      'a',
    );
    expect(
      await (databaseB.select(databaseB.appFlags)
            ..where((row) => row.key.equals('owner')))
          .map((row) => row.value)
          .getSingle(),
      'b',
    );

    await sessionA.dispose();
    expect(
      await (databaseB.select(databaseB.appFlags)
            ..where((row) => row.key.equals('owner')))
          .map((row) => row.value)
          .getSingle(),
      'b',
    );
    await sessionB.dispose();
  });
}
