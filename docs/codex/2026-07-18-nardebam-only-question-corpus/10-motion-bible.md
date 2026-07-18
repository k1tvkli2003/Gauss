# Motion Bible

## Intent

Motion should communicate selection, current position, route travel, reveal,
and drawing state. It must never delay reading or become a substitute for
feedback.

## Implemented Timing

| Interaction | Duration | Purpose |
|---|---:|---|
| Subject/section state container | 170–180 ms | Crisp selection confirmation |
| Pen toggle and inline hint | 160 ms | Show mode change without distracting from content |
| Node emphasis scale | 220 ms | Confirm the inspected/current node |
| Study Room position movement | 240 ms | Keep question changes spatially understandable |
| Map jump-to-current scroll | 620 ms | Preserve orientation over a long route |
| Mission/reveal switch where retained | 160–320 ms | Distinguish content-state changes |

## Reduced Motion

- Every listed animation checks `MediaQuery.disableAnimationsOf(context)`.
- Decorative state changes collapse to zero or 1 ms.
- Map interaction, route selection, drawing, clearing, and navigation remain
  immediate and functionally identical.
- Widget coverage includes reduced-motion Map rendering.

## Spatial Rules

- Current-node emphasis scales in place; it does not move the route.
- Jump-to-current moves the viewport along the path instead of teleporting
  content under the user.
- Footer/rail selection changes stay within their glass container.
- Direct ink follows the pointer with normalized coordinates so resizing does
  not distort stored session strokes.
- Reveal and reflection controls do not animate correctness because no
  correctness claim is made.

## Performance Guardrails

- Background art is cached at bounded decode widths.
- Path and node geometry are deterministic and avoid per-frame layout churn.
- Ink repaint is isolated to its CustomPaint layer.
- Long lists use scrollable/sliver surfaces; motion does not force an
  unbounded full-screen relayout.

## Future Gate

Any new celebration, reward, or character motion must define its trigger,
duration, reduced-motion equivalent, semantic outcome, and frame/runtime proof
before being accepted.
