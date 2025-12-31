// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BraveCore
import BraveShields
import Foundation
import Preferences
import os

private let defaultEasyListURL = URL(string: "https://easylist.to/easylist/easylist.txt")!

/// This class helps to prepare the browser during launch by ensuring the state of managers, resources and downloaders before performing additional tasks.
public actor LaunchHelper {
  public static let shared = LaunchHelper()
  static let signpost = OSSignposter(logger: ContentBlockerManager.log)
  private var loadTask: Task<(), Never>?
  private var areAdBlockServicesReady = false

  /// This method prepares the ad-block services one time so that multiple scenes can benefit from its results
  /// This is particularly important since we use a shared instance for most of our ad-block services.
  public func prepareAdBlockServices(adBlockService: AdblockService) async {
    // Check if ad-block services are already ready.
    // If so, we don't have to do anything
    guard !areAdBlockServicesReady else { return }

    // Check if we're still preparing the ad-block services
    // If so we await that task
    if let task = loadTask {
      return await task.value
    }

    // Otherwise prepare the services and await the task
    let task = Task {
      let signpostID = Self.signpost.makeSignpostID()
      ContentBlockerManager.log.debug("Loading blocking launch data")
      let state = Self.signpost.beginInterval("blockingLaunchTask", id: signpostID)

      // Fork behavior: use EasyList (custom URL) as the default adblock source.
      // We intentionally do NOT start Brave filter lists/resources downloaders here.
      var shouldForceEasyListUpdate = false
      await MainActor.run {
        if !Preferences.AppState.didInstallDefaultEasyList.value {
          let alreadyExists = CustomFilterListStorage.shared.filterListsURLs.contains(where: {
            $0.setting.externalURL == defaultEasyListURL
          })

          if !alreadyExists {
            let customURL = FilterListCustomURL(
              externalURL: defaultEasyListURL,
              isEnabled: true,
              inMemory: !CustomFilterListStorage.shared.persistChanges
            )
            CustomFilterListStorage.shared.filterListsURLs.append(customURL)
          } else if let idx = CustomFilterListStorage.shared.filterListsURLs.firstIndex(where: {
            $0.setting.externalURL == defaultEasyListURL
          }) {
            CustomFilterListStorage.shared.filterListsURLs[idx].setting.isEnabled = true
          }

          shouldForceEasyListUpdate = true
          Preferences.AppState.didInstallDefaultEasyList.value = true
        }
      }

      // Start fetching custom URL lists (includes EasyList) and load cached engines.
      await FilterListCustomURLDownloader.shared.startFetching()

      // On first run, force an immediate download/compile so adblocking works on the first navigation.
      if shouldForceEasyListUpdate {
        do {
          try await FilterListCustomURLDownloader.shared.updateFilterLists()
        } catch {
          ContentBlockerManager.log.error(
            "Failed to update EasyList on first run: \(String(describing: error))"
          )
        }
      }

      await AdBlockGroupsManager.shared.loadEnginesFromCache()

      Self.signpost.emitEvent("loadedCachedData", id: signpostID, "Loaded cached data")
      ContentBlockerManager.log.debug("Loaded blocking launch data")

      areAdBlockServicesReady = true
      Self.signpost.endInterval("blockingLaunchTask", state)
    }

    // Await the task and wait for the results
    self.loadTask = task
    await task.value
    self.loadTask = nil
  }

}

extension FilterListStorage {
  /// Return all the blocklist types that are valid for filter lists.
  fileprivate var validBlocklistTypes: Set<ContentBlockerManager.BlocklistType> {
    if filterLists.isEmpty {
      // If we don't have filter lists yet loaded, use the settings
      return Set(
        allFilterListSettings.compactMap { setting -> ContentBlockerManager.BlocklistType? in
          return setting.engineSource?.blocklistType(
            engineType: setting.engineType
          )
        }
      )
    } else {
      // If we do have filter lists yet loaded, use them as they are always the most up to date and accurate
      return Set(
        filterLists.compactMap { filterList in
          return filterList.engineSource.blocklistType(
            engineType: filterList.engineType
          )
        }
      )
    }
  }
}
extension ShieldLevel {
  /// Return a list of first launch content blocker modes that MUST be precompiled during launch
  fileprivate var firstLaunchBlockingModes: Set<ContentBlockerManager.BlockingMode> {
    switch self {
    case .standard, .disabled:
      // Disabled setting may be overriden per domain so we need to treat it as standard
      // Aggressive needs to be included because some filter lists are aggressive only
      return [.general, .standard, .aggressive]
    case .aggressive:
      // If we have aggressive mode enabled, we never use standard
      // (until we allow domain specific aggressive mode)
      return [.general, .aggressive]
    }
  }
}
