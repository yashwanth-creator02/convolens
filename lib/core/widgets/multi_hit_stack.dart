import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A [Stack] that performs hit-testing on all its children without early-exiting
/// on the first hit.
///
/// Standard Flutter [Stack] stops hit-testing as soon as the top-most child returns
/// `true` from [hitTest]. When an overlay or gesture detector sits on top of
/// underlying interactive controls (such as buttons or scrollables), standard [Stack]
/// prevents the underlying controls from entering the gesture arena.
///
/// [MultiHitStack] ensures that all overlapping children at the touch coordinates
/// are hit-tested and added to the gesture arena, allowing Flutter's gesture arena
/// to resolve the gesture naturally based on user intent (e.g. tap vs drag).
class MultiHitStack extends Stack {
  const MultiHitStack({
    super.key,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return RenderMultiHitStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMultiHitStack renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class RenderMultiHitStack extends RenderStack {
  RenderMultiHitStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  bool defaultHitTestChildren(
    BoxHitTestResult result, {
    required Offset position,
  }) {
    bool hasHit = false;
    RenderBox? child = lastChild;
    while (child != null) {
      final StackParentData childParentData =
          child.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        hasHit = true;
      }
      child = childParentData.previousSibling;
    }
    return hasHit;
  }
}
