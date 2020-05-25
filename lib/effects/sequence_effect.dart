import 'package:flutter/animation.dart';
import 'package:meta/meta.dart';

import 'dart:ui';
import 'dart:math';

import './effects.dart';
import '../position.dart';

class SequenceEffect extends PositionComponentEffect {
  final List<PositionComponentEffect> effects;
  int _currentIndex = 0;
  PositionComponentEffect _currentEffect;
  bool _currentWasAlternating;
  double _driftModifier = 0.0;

  SequenceEffect({
    @required this.effects,
    isInfinite = false,
    isAlternating = false,
  }) : super(isInfinite, isAlternating);

  @override
  set component(_comp) {
    super.component = _comp;
    final originalSize = _comp.toSize();
    final originalPosition = _comp.toPosition();
    Position currentSize = _comp.toSize();
    Position currentPosition = _comp.toPosition();
    effects.forEach((effect) {
      effect.reset();
      _comp.setBySize(currentSize);
      _comp.setByPosition(currentPosition);
      effect.component = _comp;
      if (effect is MoveEffect) {
        currentPosition = effect.destination;
      } else if (effect is ScaleEffect) {
        currentSize = Position.fromSize(effect.size);
      }
    });
    travelTime = effects.fold(0, (time, effect) => time + effect.travelTime *
        (effect.isAlternating ? 2 : 1));
    component.setBySize(originalSize);
    component.setByPosition(originalPosition);
    _currentEffect = effects.first;
    _currentWasAlternating = _currentEffect.isAlternating;
  }

  @override
  void update(double dt) {
    if (hasFinished()) {
      return;
    }
    super.update(dt);

    _currentEffect.update(dt + _driftModifier);
    _driftModifier = 0.0;
    if (_currentEffect.hasFinished()) {
      _driftModifier = _currentEffect.driftTime;
      _currentEffect.isAlternating = _currentWasAlternating;
      _currentIndex++;
      final iterationSize = isAlternating ? effects.length * 2 : effects.length;
      if (_currentIndex != 0 && _currentIndex % iterationSize == 0) {
        isInfinite ? reset() : dispose();
        return;
      }
      final orderedEffects =
          curveDirection.isNegative ? effects.reversed.toList() : effects;
      _currentEffect = orderedEffects[_currentIndex % effects.length];
      _currentWasAlternating = _currentEffect.isAlternating;
      if (isAlternating &&
          !_currentEffect.isAlternating &&
          curveDirection.isNegative) {
        // Make the effect go in reverse
        _currentEffect.isAlternating = true;
        _currentEffect.percentage = 1.0;
      }
    }
  }

  @override
  void reset() {
    super.reset();
    _currentIndex = 0;
    component = component;
  }
}
