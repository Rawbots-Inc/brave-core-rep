// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import BraveShared
import BraveUI
import DesignSystem
import Shared
import SwiftUI

public enum VPNChurnPromoType {
  case autoRenewSoonExpire
  case autoRenewDiscount
  case autoRenewFreeMonth
  case updateBillingSoonExpire
  case updateBillingExpired
  case subscribeDiscount
  case subscribeVPNProtection
  case subscribeAllDevices

  var promoImage: String {
    switch self {
    case .autoRenewSoonExpire:
      return "auto_renew _soon_image"
    case .autoRenewDiscount:
      return "auto_renew _discount_image"
    case .autoRenewFreeMonth:
      return "auto_renew _free_image"
    case .updateBillingSoonExpire, .updateBillingExpired:
      return "update_billing_expired"
    case .subscribeDiscount:
      return "auto_renew _soon_image"
    case .subscribeVPNProtection:
      return "subscribe_protection_image"
    case .subscribeAllDevices:
      return "subscribe_all-devices_image"
    }
  }

  var title: String {
      return ""
  }

  var description: String? {
      return ""
  }

  var subDescription: String? {
      return ""
  }

  var buttonTitle: String {
      return ""
  }
}

public struct VPNChurnPromoView: View {
  @Environment(\.presentationMode) @Binding private var presentationMode
  @State private var height: CGFloat?

  public var renewAction: (() -> Void)?

  public var churnPromoType: VPNChurnPromoType

  public init(churnPromoType: VPNChurnPromoType) {
    self.churnPromoType = churnPromoType
  }

  public var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        headerView
        detailView
          .padding(.bottom, 8)
        footerView
      }
      .background {
        GeometryReader { proxy in
          Color.clear
            .onAppear { height = proxy.size.height }
            .onChange(of: proxy.size.height) { newValue in
              height = newValue
            }
        }
      }
      .padding(.horizontal, 32)
    }
    .background(Color(.braveBackground))
    .frame(maxWidth: BraveUX.baseDimensionValue, maxHeight: height)
    .overlay {
      Button {
        presentationMode.dismiss()
      } label: {
        Image(braveSystemName: "leo.close")
          .renderingMode(.template)
          .foregroundColor(Color(.bravePrimary))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
      .padding([.top, .trailing], 10)
    }
    .padding(.vertical, 16)
    .scrollBounceBehavior(.basedOnSize)
  }

  private var headerView: some View {
    VStack(spacing: 24) {
      Image(churnPromoType.promoImage, bundle: .module)

      Text(churnPromoType.title)
        .font(.title)
        .multilineTextAlignment(.center)
    }
  }

  @ViewBuilder
  private var detailView: some View {
      let description = churnPromoType.description ?? ""

      Text(description)
        .font(.title3)
        .multilineTextAlignment(.center)
  }

  private var footerView: some View {
    VStack(spacing: 24) {
      Button {
        renewAction?()
        presentationMode.dismiss()
      } label: {
        Text(churnPromoType.buttonTitle)
          .padding(.vertical, 4)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(BraveFilledButtonStyle(size: .large))

      HStack(spacing: 8) {
        Text("")
          .font(.footnote)
          .foregroundColor(Color(.secondaryBraveLabel))
          .multilineTextAlignment(.center)
        Image(sharedName: "vpn_brand")
          .renderingMode(.template)
          .foregroundColor(Color(.secondaryBraveLabel))
      }
      .padding(.bottom, 16)
    }
  }
}

#if DEBUG
struct VPNChurnPromoView_Previews: PreviewProvider {
  static var previews: some View {
    VPNChurnPromoView(churnPromoType: .autoRenewSoonExpire)
      .previewLayout(.sizeThatFits)

    VPNChurnPromoView(churnPromoType: .autoRenewDiscount)
      .previewLayout(.sizeThatFits)

    VPNChurnPromoView(churnPromoType: .autoRenewFreeMonth)
      .previewLayout(.sizeThatFits)

    VPNChurnPromoView(churnPromoType: .updateBillingSoonExpire)
      .previewLayout(.sizeThatFits)

    VPNChurnPromoView(churnPromoType: .updateBillingExpired)
      .previewLayout(.sizeThatFits)
  }
}
#endif
