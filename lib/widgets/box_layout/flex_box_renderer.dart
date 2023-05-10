// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fml/widgets/layout/layout_model.dart';
import 'package:fml/widgets/viewable/viewable_widget_model.dart';

class _LayoutSizes {
  const _LayoutSizes({
    required this.mainSize,
    required this.crossSize,
    required this.allocatedSize,
  });

  final double mainSize;
  final double crossSize;
  final double allocatedSize;
}

/// Parent data for use with [FlexBoxRenderer].
class LayoutParentData extends ContainerBoxParentData<RenderBox>
{
  /// The flex factor to use for this child.
  ///
  /// If null or zero, the child is inflexible and determines its own size. If
  /// non-zero, the amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space (after placing the inflexible
  /// children) according to the flex factors of the flexible children.
  int? flex;

  /// How a flexible child is inscribed into the available space.
  ///
  /// If [flex] is non-zero, the [fit] determines whether the child fills the
  /// space the parent makes available during layout. If the fit is
  /// [FlexFit.tight], the child is required to fill the available space. If the
  /// fit is [FlexFit.loose], the child can be at most as large as the available
  /// space (but is allowed to be smaller).
  FlexFit? fit;

  ViewableWidgetModel? model;

  Size? size;

  @override
  String toString() => '${super.toString()}; flex=$flex; fit=$fit';
}

class LayoutChildData extends ParentDataWidget<LayoutParentData>
{
  /// Creates a widget that controls how a child of a [Row], [Column], or [Flex]
  /// flexes.

  ViewableWidgetModel model;

  LayoutChildData({
    required this.model,
    required super.child,
  });

  /// The flex factor to use for this child.
  ///
  /// If null or zero, the child is inflexible and determines its own size. If
  /// non-zero, the amount of space the child's can occupy in the main axis is
  /// determined by dividing the free space (after placing the inflexible
  /// children) according to the flex factors of the flexible children.
  int? flex;

  double? width;
  double? height;

  /// How a flexible child is inscribed into the available space.
  ///
  /// If [flex] is non-zero, the [fit] determines whether the child fills the
  /// space the parent makes available during layout. If the fit is
  /// [FlexFit.tight], the child is required to fill the available space. If the
  /// fit is [FlexFit.loose], the child can be at most as large as the available
  /// space (but is allowed to be smaller).
  FlexFit? fit;

  @override
  void applyParentData(RenderObject renderObject)
  {
    if (renderObject.parentData is LayoutParentData)
    {
      final LayoutParentData parentData = renderObject.parentData! as LayoutParentData;

      bool needsLayout = false;
      if (parentData.model != model)
      {
        parentData.model = model;
        needsLayout = true;
      }

      if (needsLayout)
      {
        final AbstractNode? targetParent = renderObject.parent;
        if (targetParent is RenderObject)
        {
          targetParent.markNeedsLayout();
        }
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => Flex;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('flex', flex));
  }
}

bool? _startIsTopLeft(Axis direction, TextDirection? textDirection, VerticalDirection? verticalDirection) {
  assert(direction != null);
  // If the relevant value of textDirection or verticalDirection is null, this returns null too.
  switch (direction) {
    case Axis.horizontal:
      switch (textDirection) {
        case TextDirection.ltr:
          return true;
        case TextDirection.rtl:
          return false;
        case null:
          return null;
      }
    case Axis.vertical:
      switch (verticalDirection) {
        case VerticalDirection.down:
          return true;
        case VerticalDirection.up:
          return false;
        case null:
          return null;
      }
  }
}

typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

/// Displays its children in a one-dimensional array.
///
/// ## Layout algorithm
///
/// _This section describes how the framework causes [FlexBoxRenderer] to position
/// its children._
/// _See [BoxConstraints] for an introduction to box layout models._
///
/// Layout for a [FlexBoxRenderer] proceeds in six steps:
///
/// 1. Layout each child a null or zero flex factor with unbounded main axis
///    constraints and the incoming cross axis constraints. If the
///    [crossAxisAlignment] is [CrossAxisAlignment.stretch], instead use tight
///    cross axis constraints that match the incoming max extent in the cross
///    axis.
/// 2. Divide the remaining main axis space among the children with non-zero
///    flex factors according to their flex factor. For example, a child with a
///    flex factor of 2.0 will receive twice the amount of main axis space as a
///    child with a flex factor of 1.0.
/// 3. Layout each of the remaining children with the same cross axis
///    constraints as in step 1, but instead of using unbounded main axis
///    constraints, use max axis constraints based on the amount of space
///    allocated in step 2. Children with [Flexible.fit] properties that are
///    [FlexFit.tight] are given tight constraints (i.e., forced to fill the
///    allocated space), and children with [Flexible.fit] properties that are
///    [FlexFit.loose] are given loose constraints (i.e., not forced to fill the
///    allocated space).
/// 4. The cross axis extent of the [FlexBoxRenderer] is the maximum cross axis
///    extent of the children (which will always satisfy the incoming
///    constraints).
/// 5. The main axis extent of the [FlexBoxRenderer] is determined by the
///    [mainAxisSize] property. If the [mainAxisSize] property is
///    [MainAxisSize.max], then the main axis extent of the [FlexBoxRenderer] is the
///    max extent of the incoming main axis constraints. If the [mainAxisSize]
///    property is [MainAxisSize.min], then the main axis extent of the [Flex]
///    is the sum of the main axis extents of the children (subject to the
///    incoming constraints).
/// 6. Determine the position for each child according to the
///    [mainAxisAlignment] and the [crossAxisAlignment]. For example, if the
///    [mainAxisAlignment] is [MainAxisAlignment.spaceBetween], any main axis
///    space that has not been allocated to children is divided evenly and
///    placed between the children.
///
/// See also:
///
///  * [Flex], the widget equivalent.
///  * [Row] and [Column], direction-specific variants of [Flex].
class FlexBoxRenderer extends RenderBox with ContainerRenderObjectMixin<RenderBox, LayoutParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, LayoutParentData>,
    DebugOverflowIndicatorMixin
{
  final LayoutModel model;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! LayoutParentData) {
      child.parentData = LayoutParentData();
    }
  }

  /// Creates a flex render object.
  ///
  /// By default, the flex layout is horizontal and children are aligned to the
  /// start of the main axis and the center of the cross axis.
  FlexBoxRenderer({
    Axis direction = Axis.horizontal,
    required this.model,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    Clip clipBehavior = Clip.none,
  }) : assert(direction != null),
        assert(mainAxisAlignment != null),
        assert(mainAxisSize != null),
        assert(crossAxisAlignment != null),
        assert(clipBehavior != null),
        _direction = direction,
        _mainAxisAlignment = mainAxisAlignment,
        _mainAxisSize = mainAxisSize,
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _verticalDirection = verticalDirection,
        _textBaseline = textBaseline,
        _clipBehavior = clipBehavior {

  }

  /// The direction to use as the main axis.
  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    assert(value != null);
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the main axis.
  ///
  /// If the [direction] is [Axis.horizontal], and the [mainAxisAlignment] is
  /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
  /// [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], and the [mainAxisAlignment] is
  /// either [MainAxisAlignment.start] or [MainAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  MainAxisAlignment _mainAxisAlignment;
  set mainAxisAlignment(MainAxisAlignment value) {
    assert(value != null);
    if (_mainAxisAlignment != value) {
      _mainAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// How much space should be occupied in the main axis.
  ///
  /// After allocating space to children, there might be some remaining free
  /// space. This value controls whether to maximize or minimize the amount of
  /// free space, subject to the incoming layout constraints.
  ///
  /// If some children have a non-zero flex factors (and none have a fit of
  /// [FlexFit.loose]), they will expand to consume all the available space and
  /// there will be no remaining free space to maximize or minimize, making this
  /// value irrelevant to the final layout.
  MainAxisSize get mainAxisSize => _mainAxisSize;
  MainAxisSize _mainAxisSize;
  set mainAxisSize(MainAxisSize value) {
    assert(value != null);
    if (_mainAxisSize != value) {
      _mainAxisSize = value;
      markNeedsLayout();
    }
  }

  /// How the children should be placed along the cross axis.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] must not be null.
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    assert(value != null);
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out horizontally and how to interpret
  /// `start` and `end` in the horizontal direction.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the order in which
  /// children are positioned (left-to-right or right-to-left), and the meaning
  /// of the [mainAxisAlignment] property's [MainAxisAlignment.start] and
  /// [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and either the
  /// [mainAxisAlignment] is either [MainAxisAlignment.start] or
  /// [MainAxisAlignment.end], or there's more than one child, then the
  /// [textDirection] must not be null.
  ///
  /// If the [direction] is [Axis.vertical], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [textDirection] must not be null.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  /// Determines the order to lay children out vertically and how to interpret
  /// `start` and `end` in the vertical direction.
  ///
  /// If the [direction] is [Axis.vertical], this controls which order children
  /// are painted in (down or up), the meaning of the [mainAxisAlignment]
  /// property's [MainAxisAlignment.start] and [MainAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.vertical], and either the [mainAxisAlignment]
  /// is either [MainAxisAlignment.start] or [MainAxisAlignment.end], or there's
  /// more than one child, then the [verticalDirection] must not be null.
  ///
  /// If the [direction] is [Axis.horizontal], this controls the meaning of the
  /// [crossAxisAlignment] property's [CrossAxisAlignment.start] and
  /// [CrossAxisAlignment.end] values.
  ///
  /// If the [direction] is [Axis.horizontal], and the [crossAxisAlignment] is
  /// either [CrossAxisAlignment.start] or [CrossAxisAlignment.end], then the
  /// [verticalDirection] must not be null.
  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  /// If aligning items according to their baseline, which baseline to use.
  ///
  /// Must not be null if [crossAxisAlignment] is [CrossAxisAlignment.baseline].
  TextBaseline? get textBaseline => _textBaseline;
  TextBaseline? _textBaseline;
  set textBaseline(TextBaseline? value) {
    assert(_crossAxisAlignment != CrossAxisAlignment.baseline || value != null);
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(direction != null);
    assert(crossAxisAlignment != null);
    if (firstChild != null && lastChild != firstChild) {
      // i.e. there's more than one child
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null, 'Vertical $runtimeType with multiple children has a null verticalDirection, so the layout order is undefined.');
          break;
      }
    }
    if (mainAxisAlignment == MainAxisAlignment.start ||
        mainAxisAlignment == MainAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null, 'Horizontal $runtimeType with $mainAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null, 'Vertical $runtimeType with $mainAxisAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(verticalDirection != null, 'Horizontal $runtimeType with $crossAxisAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(textDirection != null, 'Vertical $runtimeType with $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    return true;
  }

  // Set during layout if overflow occurred on the main axis.
  double _overflow = 0;
  // Check whether any meaningful overflow is present. Values below an epsilon
  // are treated as not overflowing.
  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.none], and must not be null.
  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  bool get _canComputeIntrinsics => crossAxisAlignment != CrossAxisAlignment.baseline;

  double _getIntrinsicSize({
    required Axis sizingDirection,
    required double extent, // the extent in the direction that isn't the sizing direction
    required _ChildSizingFunction childSize, // a method to find the size in the sizing direction
  }) {
    if (!_canComputeIntrinsics) {
      // Intrinsics cannot be calculated without a full layout for
      // baseline alignment. Throw an assertion and return 0.0 as documented
      // on [RenderBox.computeMinIntrinsicWidth].
      assert(
      RenderObject.debugCheckingIntrinsics,
      'Intrinsics are not available for CrossAxisAlignment.baseline.',
      );
      return 0.0;
    }
    if (_direction == sizingDirection) {
      // INTRINSIC MAIN SIZE
      // Intrinsic main size is the smallest size the flex container can take
      // while maintaining the min/max-content contributions of its flex items.
      double totalFlex = 0.0;
      double inflexibleSpace = 0.0;
      double maxFlexFractionSoFar = 0.0;
      RenderBox? child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        if (flex > 0) {
          final double flexFraction = childSize(child, extent) / _getFlex(child);
          maxFlexFractionSoFar = math.max(maxFlexFractionSoFar, flexFraction);
        } else {
          inflexibleSpace += childSize(child, extent);
        }
        final LayoutParentData childParentData = child.parentData! as LayoutParentData;
        child = childParentData.nextSibling;
      }
      return maxFlexFractionSoFar * totalFlex + inflexibleSpace;
    } else {
      // INTRINSIC CROSS SIZE
      // Intrinsic cross size is the max of the intrinsic cross sizes of the
      // children, after the flexible children are fit into the available space,
      // with the children sized using their max intrinsic dimensions.

      // Get inflexible space using the max intrinsic dimensions of fixed children in the main direction.
      final double availableMainSpace = extent;
      int totalFlex = 0;
      double inflexibleSpace = 0.0;
      double maxCrossSize = 0.0;
      RenderBox? child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        late final double mainSize;
        late final double crossSize;
        if (flex == 0) {
          switch (_direction) {
            case Axis.horizontal:
              mainSize = child.getMaxIntrinsicWidth(double.infinity);
              crossSize = childSize(child, mainSize);
              break;
            case Axis.vertical:
              mainSize = child.getMaxIntrinsicHeight(double.infinity);
              crossSize = childSize(child, mainSize);
              break;
          }
          inflexibleSpace += mainSize;
          maxCrossSize = math.max(maxCrossSize, crossSize);
        }
        final LayoutParentData childParentData = child.parentData! as LayoutParentData;
        child = childParentData.nextSibling;
      }

      // Determine the spacePerFlex by allocating the remaining available space.
      // When you're overconstrained spacePerFlex can be negative.
      final double spacePerFlex = math.max(0.0, (availableMainSpace - inflexibleSpace) / totalFlex);

      // Size remaining (flexible) items, find the maximum cross size.
      child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0) {
          maxCrossSize = math.max(maxCrossSize, childSize(child, spacePerFlex * flex));
        }
        final LayoutParentData childParentData = child.parentData! as LayoutParentData;
        child = childParentData.nextSibling;
      }

      return maxCrossSize;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) => child.getMaxIntrinsicHeight(extent),
    );
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    if (_direction == Axis.horizontal) {
      return defaultComputeDistanceToHighestActualBaseline(baseline);
    }
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  int _getFlex(RenderBox child) {
    final LayoutParentData childParentData = child.parentData! as LayoutParentData;
    return childParentData.flex ?? 0;
  }

  FlexFit _getFit(RenderBox child) {
    final LayoutParentData childParentData = child.parentData! as LayoutParentData;
    return childParentData.fit ?? FlexFit.tight;
  }

  double _getCrossSize(Size size) {
    switch (_direction) {
      case Axis.horizontal:
        return size.height;
      case Axis.vertical:
        return size.width;
    }
  }

  double _getMainSize(Size size) {
    switch (_direction) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (!_canComputeIntrinsics) {
      assert(debugCannotComputeDryLayout(
        reason: 'Dry layout cannot be computed for CrossAxisAlignment.baseline, which requires a full layout.',
      ));
      return Size.zero;
    }
    FlutterError? constraintsError;
    assert(() {
      constraintsError = _debugCheckConstraints(
        constraints: constraints,
        reportParentConstraints: false,
      );
      return true;
    }());
    if (constraintsError != null) {
      assert(debugCannotComputeDryLayout(error: constraintsError));
      return Size.zero;
    }

    final _LayoutSizes sizes = _computeSizes(
      layoutChild: ChildLayoutHelper.dryLayoutChild,
      constraints: constraints,
    );

    switch (_direction) {
      case Axis.horizontal:
        return constraints.constrain(Size(sizes.mainSize, sizes.crossSize));
      case Axis.vertical:
        return constraints.constrain(Size(sizes.crossSize, sizes.mainSize));
    }
  }

  FlutterError? _debugCheckConstraints({required BoxConstraints constraints, required bool reportParentConstraints}) {
    FlutterError? result;
    assert(() {
      final double maxMainSize = _direction == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;
      final bool canFlex = maxMainSize < double.infinity;
      RenderBox? child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0) {
          final String identity = _direction == Axis.horizontal ? 'row' : 'column';
          final String axis = _direction == Axis.horizontal ? 'horizontal' : 'vertical';
          final String dimension = _direction == Axis.horizontal ? 'width' : 'height';
          DiagnosticsNode error, message;
          final List<DiagnosticsNode> addendum = <DiagnosticsNode>[];
          if (!canFlex && (mainAxisSize == MainAxisSize.max || _getFit(child) == FlexFit.tight)) {
            error = ErrorSummary('RenderFlexBox children have non-zero flex but incoming $dimension constraints are unbounded.');
            message = ErrorDescription(
              'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
                  'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
                  'axis. Setting a flex on a child (e.g. using Expanded) indicates that the child is to '
                  'expand to fill the remaining space in the $axis direction.',
            );
            if (reportParentConstraints) { // Constraints of parents are unavailable in dry layout.
              RenderBox? node = this;
              switch (_direction) {
                case Axis.horizontal:
                  while (!node!.constraints.hasBoundedWidth && node.parent is RenderBox) {
                    node = node.parent! as RenderBox;
                  }
                  if (!node.constraints.hasBoundedWidth) {
                    node = null;
                  }
                  break;
                case Axis.vertical:
                  while (!node!.constraints.hasBoundedHeight && node.parent is RenderBox) {
                    node = node.parent! as RenderBox;
                  }
                  if (!node.constraints.hasBoundedHeight) {
                    node = null;
                  }
                  break;
              }
              if (node != null) {
                addendum.add(node.describeForError('The nearest ancestor providing an unbounded width constraint is'));
              }
            }
            addendum.add(ErrorHint('See also: https://flutter.dev/layout/'));
          } else {
            return true;
          }
          result = FlutterError.fromParts(<DiagnosticsNode>[
            error,
            message,
            ErrorDescription(
              'These two directives are mutually exclusive. If a parent is to shrink-wrap its child, the child '
                  'cannot simultaneously expand to fit its parent.',
            ),
            ErrorHint(
              'Consider setting mainAxisSize to MainAxisSize.min and using FlexFit.loose fits for the flexible '
                  'children (using Flexible rather than Expanded). This will allow the flexible children '
                  'to size themselves to less than the infinite remaining space they would otherwise be '
                  'forced to take, and then will cause the RenderFlexBox to shrink-wrap the children '
                  'rather than expanding to fit the maximum constraints provided by the parent.',
            ),
            ErrorDescription(
              'If this message did not help you determine the problem, consider using debugDumpRenderTree():\n'
                  '  https://flutter.dev/debugging/#rendering-layer\n'
                  '  http://api.flutter.dev/flutter/rendering/debugDumpRenderTree.html',
            ),
            describeForError('The affected RenderFlexBox is', style: DiagnosticsTreeStyle.errorProperty),
            DiagnosticsProperty<dynamic>('The creator information is set to', debugCreator, style: DiagnosticsTreeStyle.errorProperty),
            ...addendum,
            ErrorDescription(
              "If none of the above helps enough to fix this problem, please don't hesitate to file a bug:\n"
                  '  https://github.com/flutter/flutter/issues/new?template=2_bug.md',
            ),
          ]);
          return true;
        }
        child = childAfter(child);
      }
      return true;
    }());
    return result;
  }

  _LayoutSizes _computeSizes({required BoxConstraints constraints, required ChildLayouter layoutChild})
  {
    assert(_debugHasNecessaryDirections);
    assert(constraints != null);

    final BoxConstraints innerConstraints = _calculateConstraints();

    // set sizing
    var allocated = calculateChildSizes(innerConstraints);

    var maxMainSize  = _direction == Axis.horizontal ? _calculateWidth(allocated)  : _calculateHeight(allocated);
    var maxCrossSize = _direction == Axis.horizontal ? _calculateHeight(allocated) : _calculateWidth(allocated);

    double maxHeight = _getMaxHeight(this);
    double maxWidth  = _getMaxWidth(this);

    // Determine used flex factor, size inflexible items, calculate free space.
    int totalFlex = 0;
    double allocatedSize = 0.0; // Sum of the sizes of the non-flexible children.
    
    RenderBox? child = firstChild;
    RenderBox? lastFlexChild;
    while (child != null) 
    {
      final LayoutParentData data = child.parentData! as LayoutParentData;
      final int flex = _getFlex(child);
      if (flex > 0) 
      {
        totalFlex += flex;
        lastFlexChild = child;
      } 
      else 
      {
        allocatedSize += _getMainSize(Size(data.size?.width ?? 0, data.size?.height ?? 0));
      }
      assert(child.parentData == data);
      child = data.nextSibling;
    }
    
    // Distribute free space to flexible children.
    final double freeSpace = math.max(0.0, maxMainSize - allocatedSize);
    double allocatedFlexSpace = 0.0;
    
    if (totalFlex > 0) 
    {
      final double spacePerFlex = freeSpace / totalFlex;
      child = firstChild;
      while (child != null) 
      {
        final int flex = _getFlex(child);
        if (flex > 0) 
        {
          final double maxChildExtent = child == lastFlexChild ? (freeSpace - allocatedFlexSpace) : spacePerFlex * flex;
          late final double minChildExtent;
          switch (_getFit(child)) 
          {
            case FlexFit.tight:
              assert(maxChildExtent < double.infinity);
              minChildExtent = maxChildExtent;
              break;
            case FlexFit.loose:
              minChildExtent = 0.0;
              break;
          }
          assert(minChildExtent != null);
          final BoxConstraints innerConstraints;
          if (crossAxisAlignment == CrossAxisAlignment.stretch) {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = BoxConstraints(
                  minWidth: minChildExtent,
                  maxWidth: maxChildExtent,
                  minHeight: maxHeight,
                  maxHeight: maxHeight,
                );
                break;
              case Axis.vertical:
                innerConstraints = BoxConstraints(
                  minWidth: maxWidth,
                  maxWidth: maxWidth,
                  minHeight: minChildExtent,
                  maxHeight: maxChildExtent,
                );
                break;
            }
          } else {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = BoxConstraints(
                  minWidth: minChildExtent,
                  maxWidth: maxChildExtent,
                  maxHeight: maxHeight,
                );
                break;
              case Axis.vertical:
                innerConstraints = BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: minChildExtent,
                  maxHeight: maxChildExtent,
                );
                break;
            }
          }
          final Size childSize = layoutChild(child, innerConstraints);
          final double childMainSize = _getMainSize(childSize);
          assert(childMainSize <= maxChildExtent);
          allocatedSize += childMainSize;
          allocatedFlexSpace += maxChildExtent;
        }
        final LayoutParentData childParentData = child.parentData! as LayoutParentData;
        child = childParentData.nextSibling;
      }
    }

    return _LayoutSizes(mainSize: maxMainSize, crossSize: maxCrossSize, allocatedSize: allocatedSize);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow)
    {
      if (size > Size.zero && model.color != null)
      {
        context.canvas.drawRect(offset & size, Paint()..color = model.color!);
      }
      defaultPaint(context, offset);
      return;
    }

    // There's no point in drawing the children if we're empty.
    if (size.isEmpty) {
      return;
    }

    _clipRectLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      defaultPaint,
      clipBehavior: clipBehavior,
      oldLayer: _clipRectLayer.layer,
    );

    assert(() {
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
          'The overflowing $runtimeType has an orientation of $_direction.',
        ),
        ErrorDescription(
          'The edge of the $runtimeType that is overflowing has been marked '
              'in the rendering with a yellow and black striped pattern. This is '
              'usually caused by the contents being too big for the $runtimeType.',
        ),
        ErrorHint(
          'Consider applying a flex factor (e.g. using an Expanded widget) to '
              'force the children of the $runtimeType to fit within the available '
              'space instead of being sized to their natural size.',
        ),
        ErrorHint(
          'This is considered an error condition because it indicates that there '
              'is content that cannot be seen. If the content is legitimately bigger '
              'than the available space, consider clipping it with a ClipRect widget '
              'before putting it in the flex, or using a scrollable container rather '
              'than a Flex, like a ListView.',
        ),
      ];

      // Simulate a child rect that overflows by the right amount. This child
      // rect is never used for drawing, just for determining the overflow
      // location and amount.
      final Rect overflowChildRect;
      switch (_direction) {
        case Axis.horizontal:
          overflowChildRect = Rect.fromLTWH(0.0, 0.0, size.width + _overflow, 0.0);
          break;
        case Axis.vertical:
          overflowChildRect = Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
          break;
      }
      paintOverflowIndicator(context, offset, Offset.zero & size, overflowChildRect, overflowHints: debugOverflowHints);
      return true;
    }());
  }

  final LayerHandle<ClipRectLayer> _clipRectLayer = LayerHandle<ClipRectLayer>();

  @override
  void dispose() {
    _clipRectLayer.layer = null;
    super.dispose();
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) {
    switch (clipBehavior) {
      case Clip.none:
        return null;
      case Clip.hardEdge:
      case Clip.antiAlias:
      case Clip.antiAliasWithSaveLayer:
        return _hasOverflow ? Offset.zero & size : null;
    }
  }


  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (!kReleaseMode) {
      if (_hasOverflow) {
        header += ' OVERFLOWING';
      }
    }
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize));
    properties.add(EnumProperty<CrossAxisAlignment>('crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection, defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>('verticalDirection', verticalDirection, defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline, defaultValue: null));
  }

  double _getMaxHeight(AbstractNode? parent, {bool stopOnScroller = false})
  {
    double height = double.negativeInfinity;
    if (model.height != null && model.height! >= 0)
    {
      height = model.height!;
    }

    while (height < 0 &&  parent != null)
    {
      if (parent is RenderBox && parent.constraints.hasBoundedHeight)
      {
        height = parent.constraints.maxHeight;
      }
      else
      {
        parent = parent.parent;
      }
    }
    return height;
  }

  double _getMaxWidth(AbstractNode? parent, {bool stopOnScroller = false})
  {
    double width = double.negativeInfinity;
    if (model.width != null)
    {
      width = model.width!;
    }

    while (width < 0 &&  parent != null)
    {
      if (parent is RenderBox && parent.constraints.hasBoundedWidth)
      {
        width = parent.constraints.maxWidth;
      }
      else
      {
        parent = parent.parent;
      }
    }
    return width;
  }

  BoxConstraints _calculateConstraints()
  {
    if (crossAxisAlignment == CrossAxisAlignment.stretch)
    {
      switch (_direction)
      {
        case Axis.horizontal:
          return  BoxConstraints.tightFor(height: _calculateHeight(Size.fromHeight(constraints.maxHeight)));
        case Axis.vertical:
          return BoxConstraints.tightFor(width: _calculateWidth(Size.fromWidth(constraints.maxWidth)));
      }
    }
    else
    {
      switch (_direction)
      {
        case Axis.horizontal:
          return BoxConstraints(maxHeight: _calculateHeight(Size.fromHeight(constraints.maxHeight)));
        case Axis.vertical:
          return BoxConstraints(maxWidth: _calculateWidth(Size.fromWidth(constraints.maxWidth)));
      }
    }
  }
  double _calculateWidth(Size allocated)
  {
    double width = 0;

    if (model.width != null)
    {
      width = model.width!;
    }
    else if (model.widthPercentage != null)
    {
      width = ((model.widthPercentage!/100) * _getMaxWidth(this));
    }
    else
    {
      if (model.expand)
      {
        width = constraints.maxWidth;
        if (width == double.infinity) width = _getMaxWidth(this);
      }
      else
      {
        width = allocated.width;
      }
    }

    // get user defined constraints
    var modelConstraints = model.constraints.model;

    // must not be less than min height
    if (modelConstraints.minWidth != null && width < modelConstraints.minWidth!)
    {
      width = modelConstraints.minWidth!;
    }

    // must not be greater than max height
    if (modelConstraints.maxWidth != null && width > modelConstraints.maxWidth!)
    {
      width = modelConstraints.maxWidth!;
    }

    // must be 0 or greater
    if (width.isNegative) width = 0;

    return width;
  }

  double _calculateHeight(Size allocated)
  {
    double height = 0;

    if (model.height != null)
    {
      height = model.height!;
    }
    else if (model.heightPercentage != null)
    {
      height = ((model.heightPercentage!/100) * _getMaxHeight(this));
    }
    else
    {
      if (model.expand)
      {
        height = constraints.maxHeight;
        if (height == double.infinity) height = _getMaxHeight(this);
      }
      else
      {
        height = allocated.height;
      }
    }

    // get user defined constraints
    var myConstraints = model.constraints.model;

    // must not be less than min height
    if (myConstraints.minHeight != null && height < myConstraints.minHeight!)
    {
      height = myConstraints.minHeight!;
    }

    // must not be greater than max height
    if (myConstraints.maxHeight != null && height > myConstraints.maxHeight!)
    {
      height = myConstraints.maxHeight!;
    }

    // must be 0 or greater
    if (height.isNegative) height = 0;

    return height;
  }

  Size calculateChildSizes(BoxConstraints parentConstraints)
  {
    var idParent = model.id;
    print('Parent id is $idParent');

    double myMaxHeight = _getMaxHeight(parent);
    double myMaxWidth  = _getMaxWidth(parent);
    double myWidth  = 0;
    double myHeight = 0;
    
    RenderBox? child = firstChild;
    while (child != null)
    {
      if (child.parentData is LayoutParentData && (child.parentData as LayoutParentData).model != null)
      {
        var childData = (child.parentData as LayoutParentData);
        var childConstraints = parentConstraints;
        var childModel = childData.model!;

        var idChild = childModel.id;
        print('Child id is $idChild');

        bool flexible = _direction == Axis.horizontal ? childModel.isHorizontallyExpanding() : childModel.isVerticallyExpanding();

        // set width
        if (childModel.width != null)
        {
          var width = childModel.width;
          childConstraints = childConstraints.tighten(width: width);
          if (_direction == Axis.horizontal) flexible = false;
        }

        else if (childModel.widthPercentage != null)
        {
          var width = ((childModel.widthPercentage!/100) * myMaxWidth);
          childConstraints = childConstraints.tighten(width: width);
          if (_direction == Axis.horizontal) flexible = false;
        }

        // set height
        if (childModel.height != null)
        {
          var height = childModel.height;
          childConstraints = childConstraints.tighten(height: height);
          if (_direction == Axis.vertical) flexible = false;
        }

        else if (childModel.heightPercentage != null)
        {
          var height = ((childModel.heightPercentage!/100) * myMaxHeight);
          childConstraints = childConstraints.tighten(height: height);
          if (_direction == Axis.vertical) flexible = false;
        }

        if (flexible)
        {
          childData.flex = childModel.flex ?? 1;
        }

        else
        {
          if (!childConstraints.hasBoundedWidth && childModel.isHorizontallyExpanding())
          {
           childConstraints = childConstraints.tighten(width: myWidth);
          }

          if (!childConstraints.hasBoundedHeight && childModel.isVerticallyExpanding())
          {
            childConstraints = childConstraints.tighten(height: myMaxHeight);
          }


          childData.size = ChildLayoutHelper.layoutChild(child, childConstraints);
          childData.flex = 0;
        }

        // set dimensions
        switch (_direction)
        {
          case Axis.horizontal:
            myWidth  = myWidth + (childData.size?.width  ?? 0);
            myHeight = max(myHeight, (childData.size?.height ?? 0));
            break;

          case Axis.vertical:
            myHeight = myHeight + (childData.size?.height  ?? 0);
            myWidth  = max(myWidth, (childData.size?.width ?? 0));
            break;
        }
      }
      child = childAfter(child);
    }
    
    Size allocated = Size(myWidth, myHeight);
    return allocated;
  }

  @override
  void performLayout()
  {
    final BoxConstraints constraints = this.constraints;

    final _LayoutSizes sizes = _computeSizes(
      layoutChild: ChildLayoutHelper.layoutChild,
      constraints: constraints,
    );

    final double allocatedSize = sizes.allocatedSize;
    double actualSize = sizes.mainSize;
    double crossSize = sizes.crossSize;
    double maxBaselineDistance = 0.0;
    if (crossAxisAlignment == CrossAxisAlignment.baseline) {
      RenderBox? child = firstChild;
      double maxSizeAboveBaseline = 0;
      double maxSizeBelowBaseline = 0;
      while (child != null)
      {
        assert(() {
          if (textBaseline == null) {
            throw FlutterError('To use FlexAlignItems.baseline, you must also specify which baseline to use using the "baseline" argument.');
          }
          return true;
        }());
        final double? distance = child.getDistanceToBaseline(textBaseline!, onlyReal: true);
        if (distance != null) {
          maxBaselineDistance = math.max(maxBaselineDistance, distance);
          maxSizeAboveBaseline = math.max(
            distance,
            maxSizeAboveBaseline,
          );
          maxSizeBelowBaseline = math.max(
            child.size.height - distance,
            maxSizeBelowBaseline,
          );
          crossSize = math.max(maxSizeAboveBaseline + maxSizeBelowBaseline, crossSize);
        }
        final LayoutParentData childParentData = child.parentData! as LayoutParentData;
        child = childParentData.nextSibling;
      }
    }

    // Align items along the main axis.
    switch (_direction) {
      case Axis.horizontal:
        size = constraints.constrain(Size(actualSize, crossSize));
        actualSize = size.width;
        crossSize = size.height;
        break;
      case Axis.vertical:
        size = constraints.constrain(Size(crossSize, actualSize));
        actualSize = size.height;
        crossSize = size.width;
        break;
    }
    final double actualSizeDelta = actualSize - allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);
    final double remainingSpace = math.max(0.0, actualSizeDelta);
    late final double leadingSpace;
    late final double betweenSpace;
    // flipMainAxis is used to decide whether to lay out
    // left-to-right/top-to-bottom (false), or right-to-left/bottom-to-top
    // (true). The _startIsTopLeft will return null if there's only one child
    // and the relevant direction is null, in which case we arbitrarily decide
    // to flip, but that doesn't have any detectable effect.
    final bool flipMainAxis = !(_startIsTopLeft(direction, textDirection, verticalDirection) ?? true);
    switch (_mainAxisAlignment) {
      case MainAxisAlignment.start:
        leadingSpace = 0.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.end:
        leadingSpace = remainingSpace;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.center:
        leadingSpace = remainingSpace / 2.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.spaceBetween:
        leadingSpace = 0.0;
        betweenSpace = childCount > 1 ? remainingSpace / (childCount - 1) : 0.0;
        break;
      case MainAxisAlignment.spaceAround:
        betweenSpace = childCount > 0 ? remainingSpace / childCount : 0.0;
        leadingSpace = betweenSpace / 2.0;
        break;
      case MainAxisAlignment.spaceEvenly:
        betweenSpace = childCount > 0 ? remainingSpace / (childCount + 1) : 0.0;
        leadingSpace = betweenSpace;
        break;
    }

    // Position elements
    double childMainPosition = flipMainAxis ? actualSize - leadingSpace : leadingSpace;
    RenderBox? child = firstChild;
    while (child != null)
    {
      final LayoutParentData data = child.parentData! as LayoutParentData;

      final double childCrossPosition;
      switch (_crossAxisAlignment)
      {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition = _startIsTopLeft(flipAxis(direction), textDirection, verticalDirection)
              == (_crossAxisAlignment == CrossAxisAlignment.start)
              ? 0.0
              : crossSize - _getCrossSize(child.size);
          break;
        case CrossAxisAlignment.center:
          childCrossPosition = crossSize / 2.0 - _getCrossSize(child.size) / 2.0;
          break;
        case CrossAxisAlignment.stretch:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.baseline:
          if (_direction == Axis.horizontal) {
            assert(textBaseline != null);
            final double? distance = child.getDistanceToBaseline(textBaseline!, onlyReal: true);
            if (distance != null) {
              childCrossPosition = maxBaselineDistance - distance;
            } else {
              childCrossPosition = 0.0;
            }
          } else {
            childCrossPosition = 0.0;
          }
          break;
      }
      if (flipMainAxis) {
        childMainPosition -= _getMainSize(child.size);
      }
      switch (_direction) {
        case Axis.horizontal:
          data.offset = Offset(childMainPosition, childCrossPosition);
          break;
        case Axis.vertical:
          data.offset = Offset(childCrossPosition, childMainPosition);
          break;
      }
      if (flipMainAxis) {
        childMainPosition -= betweenSpace;
      } else {
        childMainPosition += _getMainSize(child.size) + betweenSpace;
      }
      child = data.nextSibling;
    }
  }
}

