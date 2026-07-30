# Flutter media decode gate

## Purpose

Question media must be viable in the actual Flutter runtime before a
certification record can ever be considered for admission. A filesystem hash
alone cannot prove that Flutter can resolve the shipped asset name or decode
its bytes on the application's rendering stack.

`flutter_app/test/corpus_media_asset_test.dart` creates the real
`QuestionBankRepository`, gathers every `ImageBlock` from all stem, option,
solution, and shortcut blocks, loads each asset through `rootBundle`, and asks
Flutter's `instantiateImageCodec` for a frame. It decodes at one pixel only to
keep the audit bounded; this still validates the image payload and the runtime
asset route without altering the corpus.

## Result

```text
questions inspected: 3,672
unique question-media assets: 3,410
Flutter bundle resolution: passed
Flutter codec decode: passed
observed test duration: 21 seconds
```

## Boundary

This is a technical render-readiness receipt, not semantic certification. It
does not prove that an asset is the right diagram, has an uncropped question,
matches an option, is mathematically legible, or is faithful to the missing
original PDF. Those remain fail-closed extraction, source-fidelity, and
independent-review requirements; no manifest record was promoted or made
usable by this test.
