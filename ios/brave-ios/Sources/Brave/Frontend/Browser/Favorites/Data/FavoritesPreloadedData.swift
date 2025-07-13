// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BraveShared
import Foundation
import Shared
import os.log

typealias FavoriteSite = (url: URL, title: String)

struct FavoritesPreloadedData {
  static let youtube = FavoriteSite(
    url: URL(string: "https://www.youtube.com/")!,
    title: "YouTube"
  )
  static let wikipedia = FavoriteSite(
    url: URL(string: "https://www.wikipedia.org/")!,
    title: "Wikipedia"
  )
  static let facebook = FavoriteSite(
    url: URL(string: "https://www.facebook.com/")!,
    title: "Facebook"
  )
//  static let brave = FavoriteSite(
//    url: URL(string: "https://brave.com/whats-new/")!,
//    title: "What's new in Brave"
//  )
  static let popularFavorites = [youtube, wikipedia, facebook]

  private struct TopSiteForRegion: Codable {
    let region: String
    let topSites: [TopSite]

    private enum CodingKeys: String, CodingKey {
      case region = "region_id"
      case topSites = "top_sites"
    }
  }

  private struct TopSite: Codable {
    let name: String
    let url: String
  }

  /// Returns a list of websites that should be preloaded for specific region. Currently all users get the same websites.
    static func getList() async -> [FavoriteSite] {
    func appendPopularEnglishWebsites() -> [FavoriteSite] {
      var list = [FavoriteSite]()

      if let url = URL(string: "https://m.youtube.com") {
        list.append(FavoriteSite(url: url, title: "YouTube"))
      }

      if let url = URL(string: "https://www.amazon.com/") {
        list.append(FavoriteSite(url: url, title: "Amazon"))
      }

      if let url = URL(string: "https://www.wikipedia.org/") {
        list.append(FavoriteSite(url: url, title: "Wikipedia"))
      }

      if let url = URL(string: "https://x.com/") {
        list.append(FavoriteSite(url: url, title: "X"))
      }

      if let url = URL(string: "https://reddit.com/") {
        list.append(FavoriteSite(url: url, title: "Reddit"))
      }

//      if let url = URL(string: "https://brave.com/msupport/") {
//        list.append(FavoriteSite(url: url, title: Strings.NTP.braveSupportFavoriteTitle))
//      }

      return list
    }

    func appendJapaneseWebsites() -> [FavoriteSite] {
      var list = [FavoriteSite]()

      if let url = URL(string: "https://m.youtube.com/") {
        list.append(FavoriteSite(url: url, title: "YouTube"))
      }

      if let url = URL(string: "https://m.yahoo.co.jp/") {
        list.append(FavoriteSite(url: url, title: "Yahoo! JAPAN"))
      }

      if let url = URL(string: "https://x.com/") {
        list.append(FavoriteSite(url: url, title: "X"))
      }

      return list
    }

    var preloadedFavorites = [FavoriteSite]()

    // Locale consists of language and region, region makes more sense when it comes to setting
    // preloaded websites imo. Empty string will go to the default switch case
//    let region = Locale.current.region?.identifier ?? ""
//    Logger.module.debug("Preloading favorites, current region: \(region)")

//    guard let fileURL = Bundle.module.url(forResource: "top_sites_by_region", withExtension: "json") else {
//      Logger.module.error("Failed to get bundle url for \"top_sites_by_region.json\"")
//      return popularFavorites
//    }

//    guard let file = await AsyncFileManager.default.contents(atPath: fileURL.path(percentEncoded: false)) else {
//      Logger.module.error("Failed to read \"top_sites_by_region.json\"")
//      return popularFavorites
//    }

//    do {
//      let json = try JSONDecoder().decode([TopSiteForRegion].self, from: file)
//      if let topSitesForRegion = json.first(where: { $0.region == region }) {
//        return topSitesForRegion.topSites.compactMap { topSite in
//          if let url = URL(string: topSite.url) {
//            return FavoriteSite(url, title: topSite.name)
//          }
//          return nil
//        }
//      }
//      return popularFavorites
//    } catch {
//      Logger.module.error(
//        "Failed to decode \"top_sites_by_region.json\": \(error.localizedDescription)"
//      )
//      return popularFavorites
//    }
        return popularFavorites
  }
}
