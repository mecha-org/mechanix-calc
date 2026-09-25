// Copyright 2021 Sony Corporation. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include <mechanix_common/mechanix_common_plugin.h>
#include <mechanix_common/dbus_instance_manager.h>

#include "flutter_embedder_options.h"
#include "flutter_window.h"

int main(int argc, char **argv)
{
  // 1. Initialize Instance Manager (no runtime arguments needed for calc)
  std::string app_id = "mechanix_calculator";
  auto* mechanix_common = mechanix::MechanixCommon::GetInstance();

  std::vector<std::string> args;
  for (int i = 1; i < argc; ++i) {
    args.emplace_back(argv[i]);
  }

  // 2. Check if another instance is running
  if (!mechanix_common->RegisterSingletonCheck(app_id, args)) {
    return 0;
  }

  FlutterEmbedderOptions options;
  if (!options.Parse(argc, argv))
  {
    return 0;
  }

  // Creates the Flutter project.
  const auto bundle_path = options.BundlePath();
  const std::wstring fl_path(bundle_path.begin(), bundle_path.end());
  flutter::DartProject project(fl_path);
  auto command_line_arguments = std::vector<std::string>();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  flutter::FlutterViewController::ViewProperties view_properties = {};
  view_properties.width = 540;
  view_properties.height = 620;
  view_properties.view_mode = options.WindowViewMode();
  view_properties.view_rotation = options.WindowRotation();
  view_properties.title = options.WindowTitle();
  view_properties.app_id = options.WindowAppID();
  view_properties.use_mouse_cursor = options.IsUseMouseCursor();
  view_properties.use_onscreen_keyboard = options.IsUseOnscreenKeyboard();
  view_properties.use_window_decoration = options.IsUseWindowDecoraation();
  view_properties.text_scale_factor = options.TextScaleFactor();
  view_properties.enable_high_contrast = options.EnableHighContrast();
  view_properties.force_scale_factor = options.IsForceScaleFactor();
  view_properties.scale_factor = options.ScaleFactor();
  view_properties.enable_vsync = options.EnableVsync();

  // The Flutter instance hosted by this window.
  FlutterWindow window(view_properties, project);
  if (!window.OnCreate())
  {
    return 0;
  }
  window.Run();
  window.OnDestroy();

  return 0;
}
