// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'view.dart';

export 'package:flutter/gestures.dart' show HitTestResult;

/// The glue between the render tree and the Flutter engine.
abstract class Renderer extends Scheduler
  implements HitTestable {

  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onMetricsChanged = handleMetricsChanged;
    initRenderView();
    assert(renderView != null);
    assert(() {
      initServiceExtensions();
      return true;
    });
    addPersistentFrameCallback(_handlePersistentFrameCallback);
  }

  static Renderer _instance;
  static Renderer get instance => _instance;

  void initRenderView() {
    if (renderView == null) {
      renderView = new RenderView();
      renderView.scheduleInitialFrame();
    }
    handleMetricsChanged(); // configures renderView's metrics
  }

  /// The render tree that's attached to the output surface.
  RenderView get renderView => _renderView;
  RenderView _renderView;
  void set renderView(RenderView value) {
    assert(value != null);
    if (_renderView == value)
      return;
    if (_renderView != null)
      _renderView.detach();
    _renderView = value;
    _renderView.attach();
  }

  void handleMetricsChanged() {
    assert(renderView != null);
    renderView.rootConstraints = new ViewConstraints(size: ui.window.size);
  }

  void _handlePersistentFrameCallback(Duration timeStamp) {
    beginFrame();
  }

  /// Pump the rendering pipeline to generate a frame.
  void beginFrame() {
    assert(renderView != null);
    RenderObject.flushLayout();
    RenderObject.flushCompositingBits();
    RenderObject.flushPaint();
    renderView.compositeFrame();
  }

  void hitTest(HitTestResult result, Point position) {
    assert(renderView != null);
    renderView.hitTest(result, position: position);
    super.hitTest(result, position);
  }
}

/// Prints a textual representation of the entire render tree.
void debugDumpRenderTree() {
  debugPrint(Renderer.instance?.renderView?.toStringDeep());
}

/// Prints a textual representation of the entire layer tree.
void debugDumpLayerTree() {
  debugPrint(Renderer.instance?.renderView?.layer?.toStringDeep());
}

/// A concrete binding for applications that use the Rendering framework
/// directly. This is the glue that binds the framework to the Flutter engine.
class RenderingFlutterBinding extends BindingBase with Scheduler, Renderer, Gesturer {
  RenderingFlutterBinding({ RenderBox root }) {
    assert(renderView != null);
    renderView.child = root;
  }
}
