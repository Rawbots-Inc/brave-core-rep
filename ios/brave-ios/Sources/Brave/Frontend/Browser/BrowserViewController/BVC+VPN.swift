// Copyright 2024 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import UIKit

extension BrowserViewController {
  /// Shows a vpn screen based on vpn state.
  public func presentCorrespondingVPNViewController() {
    if BraveSkusManager.keepShowingSessionExpiredState {
      let alert = BraveSkusManager.sessionExpiredStateAlert(loginCallback: { [unowned self] _ in
        self.openURLInNewTab(
          .brave.account,
          isPrivate: self.privateBrowsingManager.isPrivateBrowsing,
          isPrivileged: false
        )
      })

      present(alert, animated: true)
      return
    }

  }
}
