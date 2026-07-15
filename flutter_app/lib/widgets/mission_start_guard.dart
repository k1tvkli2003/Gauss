import 'package:flutter/material.dart';

import '../domain/models.dart';

Future<bool> confirmMissionReplacement(
  BuildContext context,
  ResumableMission? saved,
) async {
  if (saved == null) return true;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start a new mission?'),
          content: const Text(
            'Your recorded answers stay in local history, but the current unfinished queue will no longer be resumable.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep saved mission'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start new'),
            ),
          ],
        ),
      ) ??
      false;
}
