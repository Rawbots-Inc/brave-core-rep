/* Copyright (c) 2021 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include "brave/components/brave_vpn/common/features.h"

#include "base/feature_list.h"
#include "build/build_config.h"

namespace brave_vpn {

namespace features {

// Tắt Brave VPN ở mọi platform
BASE_FEATURE(kBraveVPN,
             base::FEATURE_DISABLED_BY_DEFAULT);

// Tắt UI link subscription trên Android
BASE_FEATURE(kBraveVPNLinkSubscriptionAndroidUI,
             base::FEATURE_DISABLED_BY_DEFAULT);

#if BUILDFLAG(IS_WIN)
// Tắt luôn DNS protection + Wireguard service trên Windows
BASE_FEATURE(kBraveVPNDnsProtection,
             base::FEATURE_DISABLED_BY_DEFAULT);
BASE_FEATURE(kBraveVPNUseWireguardService,
             base::FEATURE_DISABLED_BY_DEFAULT);
#endif

#if BUILDFLAG(IS_MAC)
// Cái này vốn đã DISABLED sẵn, giữ nguyên cũng được
BASE_FEATURE(kBraveVPNEnableWireguardForOSX,
             base::FEATURE_DISABLED_BY_DEFAULT);
#endif

}  // namespace features

}  // namespace brave_vpn
