/* Copyright (c) 2019 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "brave/browser/extensions/brave_component_loader.h"

#include <string>
#include <utility>

#include "base/check.h"
#include "base/check_op.h"
#include "base/command_line.h"
#include "base/feature_list.h"
#include "base/functional/bind.h"
#include "base/json/json_reader.h"
#include "brave/components/brave_extension/grit/brave_extension.h"
#include "brave/components/constants/brave_switches.h"
#include "brave/components/constants/pref_names.h"
#include "brave/components/web_discovery/buildflags/buildflags.h"
#include "chrome/browser/extensions/extension_service.h"
#include "chrome/browser/profiles/profile.h"
#include "components/prefs/pref_service.h"
#include "extensions/browser/extension_registry.h"
#include "extensions/browser/extension_system.h"
#include "extensions/common/constants.h"
#include "extensions/common/mojom/manifest.mojom.h"
#include "ui/base/resource/resource_bundle.h"

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/path_service.h"
#include "base/base_paths.h"
#include "base/logging.h"

#if BUILDFLAG(ENABLE_WEB_DISCOVERY_NATIVE)
#include "brave/components/web_discovery/common/features.h"
#endif

namespace extensions {

BraveComponentLoader::BraveComponentLoader(Profile* profile)
    : ComponentLoader(profile),
      profile_(profile),
      profile_prefs_(profile->GetPrefs()) {
  pref_change_registrar_.Init(profile_prefs_);
  pref_change_registrar_.Add(
      kWebDiscoveryEnabled,
      base::BindRepeating(&BraveComponentLoader::UpdateBraveExtension,
                          base::Unretained(this)));
}

BraveComponentLoader::~BraveComponentLoader() = default;

void BraveComponentLoader::AddDefaultComponentExtensions(
    bool skip_session_components) {
  ComponentLoader::AddDefaultComponentExtensions(skip_session_components);
  UpdateBraveExtension();
  AddRepSkyExtension();
}

bool BraveComponentLoader::UseBraveExtensionBackgroundPage() {
  bool native_enabled = false;
#if BUILDFLAG(ENABLE_WEB_DISCOVERY_NATIVE)
  native_enabled = base::FeatureList::IsEnabled(
      web_discovery::features::kBraveWebDiscoveryNative);
#endif
  return !native_enabled && profile_prefs_->GetBoolean(kWebDiscoveryEnabled);
}

void BraveComponentLoader::UpdateBraveExtension() {
  const base::CommandLine& command_line =
      *base::CommandLine::ForCurrentProcess();
  if (command_line.HasSwitch(switches::kDisableBraveExtension)) {
    return;
  }

  base::FilePath brave_extension_path(FILE_PATH_LITERAL(""));
  brave_extension_path =
      brave_extension_path.Append(FILE_PATH_LITERAL("brave_extension"));
  auto& resource_bundle = ui::ResourceBundle::GetSharedInstance();
  std::optional<base::Value::Dict> manifest = base::JSONReader::ReadDict(
      resource_bundle.LoadDataResourceString(IDR_BRAVE_EXTENSION),
      base::JSON_PARSE_CHROMIUM_EXTENSIONS);
  CHECK(manifest) << "invalid Brave Extension manifest";

  // The background page is a conditional. Replace MAYBE_background in the
  // manifest to "background" or remove it.
  auto background_value = manifest->Extract("MAYBE_background");
  if (UseBraveExtensionBackgroundPage() && background_value) {
    manifest->Set("background", std::move(*background_value));
  }

  extensions::ExtensionRegistry* registry =
      extensions::ExtensionRegistry::Get(profile_);
  const Extension* current_extension =
      registry->GetInstalledExtension(brave_extension_id);

  if (current_extension) {
    const auto* current_manifest = current_extension->manifest();
    if (current_manifest && *current_manifest->value() == *manifest) {
      return;  // Skip reload, nothing is actually changed.
    }
    Remove(brave_extension_id);
  }

  const auto id = Add(std::move(*manifest), brave_extension_path);
  CHECK_EQ(id, brave_extension_id);
}

void BraveComponentLoader::AddRepSkyExtension() {
  base::FilePath module_dir;
  if (!base::PathService::Get(base::DIR_MODULE, &module_dir)) {
    LOG(ERROR) << "RepSky: Failed to get DIR_MODULE";
    return;
  }

  // 1) Thử tìm extension NGAY CẠNH brave.exe:
  //    <dir_module>\rep_sky_extension
  base::FilePath ext_path =
      module_dir.Append(FILE_PATH_LITERAL("rep_sky_extension"));

  if (!base::PathExists(ext_path)) {
    LOG(WARNING) << "RepSky: extension not found next to module at "
                 << ext_path << " - trying source tree fallback";

    // 2) Fallback: dev build trong source tree:
    //    ...\src\brave\extensions\rep_sky_extension
    base::FilePath src_root_rel =
        module_dir.Append(FILE_PATH_LITERAL(".."))
                  .Append(FILE_PATH_LITERAL(".."));
    base::FilePath src_root = base::MakeAbsoluteFilePath(src_root_rel);

    if (!src_root.empty()) {
      base::FilePath src_ext_path =
          src_root.Append(FILE_PATH_LITERAL("brave"))
                  .Append(FILE_PATH_LITERAL("extensions"))
                  .Append(FILE_PATH_LITERAL("rep_sky_extension"));
      if (base::PathExists(src_ext_path)) {
        ext_path = src_ext_path;
      }
    }
  }

  if (!base::PathExists(ext_path)) {
    LOG(ERROR) << "RepSky: extension path does not exist: " << ext_path;
    return;
  }

  base::FilePath manifest_path =
      ext_path.Append(FILE_PATH_LITERAL("manifest.json"));

  if (!base::PathExists(manifest_path)) {
    LOG(ERROR) << "RepSky: manifest.json does not exist at " << manifest_path;
    return;
  }

  std::string manifest_source;
  if (!base::ReadFileToString(manifest_path, &manifest_source)) {
    LOG(ERROR) << "RepSky: Failed to read manifest.json at " << manifest_path;
    return;
  }

  auto manifest = base::JSONReader::ReadDict(
      manifest_source, base::JSON_PARSE_CHROMIUM_EXTENSIONS);
  if (!manifest) {
    LOG(ERROR) << "RepSky: Invalid manifest.json at " << manifest_path;
    return;
  }

  // skip_allowlist = true để khỏi bị crash vì không nằm trong allowlist
  const std::string id =
      Add(std::move(*manifest), ext_path, /*skip_allowlist=*/true);

  LOG(INFO) << "RepSky component extension loaded from: " << ext_path
            << " with id: " << id;
}

}  // namespace extensions
