// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import Foundation
import UIKit

extension URL {
  public enum Brave {
    public static let community = URL(string: "https://rep.run/")!
    public static let account = URL(string: "https://rep.run/")!
    public static let privacy = URL(string: "https://rep.run/privacy/privacy-policy")!
    public static let braveNews = URL(string: "https://rep.run/")!
    public static let braveNewsPrivacy = URL(string: "https://rep.run/")!
    public static let braveOffers = URL(string: "https://rep.run/")!
    public static let playlist = URL(string: "https://rep.run/")!
    public static let rewardsOniOS = URL(string: "https://rep.run/")!
    public static let rewardsUnverifiedPublisherLearnMoreURL = URL(
      string: "https://rep.run/"
    )!
    public static let termsOfUse = URL(string: "https://rep.run/privacy/terms-of-service")!
    public static let batTermsOfUse = URL(
      string: "https://basicattentiontoken.org/user-terms-of-service/"
    )!
    public static let ntpTutorialPage = URL(string: "https://rep.run/")!
    public static let privacyFeatures = URL(string: "https://rep.run/")!
    public static let support = URL(string: "https://rep.run/support")!
    public static let p3aHelpArticle = URL(
      string: "https://rep.run/support"
    )!
    public static let braveVPNFaq = URL(
      string: "https://rep.run/support"
    )!
    public static let braveVPNLinkReceiptProd = URL(
      string: "https://rep.run/support"
    )!
    public static let braveVPNLinkReceiptStaging = URL(
      string: "https://rep.run"
    )!
    public static let braveVPNLinkReceiptDev = URL(
      string: "https://rep.run"
    )!
    public static let braveVPNRefreshCredentials = URL(
      string: "https://rep.run"
    )!
    public static let safeBrowsingHelp = URL(
      string: "https://rep.run"
    )!
    public static let screenTimeHelp = URL(
      string: "https://rep.run"
    )!
    public static let braveLeoManageSubscriptionProd = URL(
      string: "https://rep.run"
    )!
    public static let braveLeoManageSubscriptionStaging = URL(
      string: "https://rep.run"
    )!
    public static let braveLeoManageSubscriptionDev = URL(
      string: "https://rep.run"
    )!
    public static let braveLeoLinkReceiptProd = URL(
      string: "https://rep.run"
    )!
    public static let braveLeoLinkReceiptStaging = URL(
      string: "https://rep.run"
    )!
    public static let braveLeoLinkReceiptDev = URL(
      string: "https://rep.run/support"
    )!
    public static let braveLeoRefreshCredentials = URL(
      string: "https://rep.run"
    )!
    public static let braveLeoModelCategorySupport = URL(
      string:
        "https://rep.run/support"
    )!
    public static let braveVPNSmartProxySupport = URL(
      string:
        "https://rep.run/support"
    )!
    public static let braveVPNKillSwitchSupport = URL(
      string:
        "https://rep.run/support"
    )!
  }
  public enum Apple {
    public static let manageSubscriptions = URL(
      string: "https://apps.apple.com/account/subscriptions"
    )

    public static let dataImportSupport = URL(
      string: "https://support.apple.com/en-ca/guide/iphone/iph1852764a6/18.0/ios/18.0"
    )!
  }
  public static let brave = Brave.self
  public static let apple = Apple.self
}

public struct AppURLScheme {
  /// The apps URL scheme for the current build channel
  public static var appURLScheme: String {
    Bundle.main.infoDictionary?["BRAVE_URL_SCHEME"] as? String ?? "brave"
  }
}
