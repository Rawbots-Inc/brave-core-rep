/* Copyright (c) 2018 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include "chrome/installer/mini_installer/appid.h"

namespace google_update {

#if defined(OFFICIAL_BUILD)
const wchar_t kAppGuid[] = L"{CDAE8E45-B4B1-4162-975F-A68C277DC32D}";
const wchar_t kMultiInstallAppGuid[] =
    L"{F7526127-0B8A-406F-8998-282BEA40103A}";
const wchar_t kBetaAppGuid[] = L"{9ABF2964-72CC-4C55-B14A-1CA7B03ACE26}";
const wchar_t kDevAppGuid[] = L"{3AD634C3-609B-45C6-8647-921D477E0F1E}";
const wchar_t kSxSAppGuid[] = L"{AD9E2C1C-DD70-4BD5-B07B-575AC6992E17}";
#else
const wchar_t kAppGuid[] = L"";
const wchar_t kMultiInstallAppGuid[] = L"";
#endif

}  // namespace google_update
