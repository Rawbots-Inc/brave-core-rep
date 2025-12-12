/* Copyright (c) 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "chrome/installer/util/google_update_constants.h"

#define kChromeUpgradeCode kChromeUpgradeCode_Unused
#define kGoogleUpdateUpgradeCode kGoogleUpdateUpgradeCode_Unused
#define kGoogleUpdateSetupExe kGoogleUpdateSetupExe_Unused
#define kRegPathClients kRegPathClients_Unused
#define kRegPathClientState kRegPathClientState_Unused
#define kRegPathClientStateMedium kRegPathClientStateMedium_Unused
#define kRegPathGoogleUpdate kRegPathGoogleUpdate_Unused

#include <chrome/installer/util/google_update_constants.cc>

#undef kChromeUpgradeCode
#undef kGoogleUpdateUpgradeCode
#undef kGoogleUpdateSetupExe
#undef kRegPathClients
#undef kRegPathClientState
#undef kRegPathClientStateMedium
#undef kRegPathGoogleUpdate

namespace google_update {

const wchar_t kChromeUpgradeCode[] = L"{CDAE8E45-B4B1-4162-975F-A68C277DC32D}";
const wchar_t kGoogleUpdateUpgradeCode[] =
    L"{7702F1B3-1702-4317-9E8C-B54A106B75FA}";
const wchar_t kGoogleUpdateSetupExe[] = L"BraveUpdateSetup.exe";
const wchar_t kRegPathClients[] =
    L"Software\\RawbotsInteractive\\Update\\Clients";
const wchar_t kRegPathClientState[] =
    L"Software\\RawbotsInteractive\\Update\\ClientState";
const wchar_t kRegPathClientStateMedium[] =
    L"Software\\RawbotsInteractive\\Update\\ClientStateMedium";
const wchar_t kRegPathGoogleUpdate[] = L"Software\\RawbotsInteractive\\Update";

}  // namespace google_update
