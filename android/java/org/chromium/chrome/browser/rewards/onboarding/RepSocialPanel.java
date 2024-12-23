/**
 * Copyright (c) 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.chromium.chrome.browser.rewards.onboarding;

import android.content.Context;
import android.os.Build;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.PopupWindow;

import androidx.core.content.res.ResourcesCompat;

import org.chromium.chrome.R;
import org.chromium.chrome.browser.BraveRewardsNativeWorker;
import org.chromium.chrome.browser.BraveRewardsObserver;
import org.chromium.chrome.browser.rewards.BraveRewardsPanel;
import org.chromium.chrome.browser.util.TabUtils;

/**
 * This class is used to show rewards onboarding UI
 **/
public class RepSocialPanel implements BraveRewardsObserver {
    private final View mAnchorView;
    private final PopupWindow mPopupWindow;
    private View mPopupView;

    private BraveRewardsNativeWorker mBraveRewardsNativeWorker;
    private WebView modalWebView;
    private String url = "";

    private static final String TAG = "RepSocialPanel";

    // Primary constructor with URL
    public RepSocialPanel(View anchorView, int deviceWidth, String url) {
        mAnchorView = anchorView;
        mPopupWindow = new PopupWindow(anchorView.getContext());
        mPopupWindow.setHeight(ViewGroup.LayoutParams.WRAP_CONTENT);
        mPopupWindow.setBackgroundDrawable(ResourcesCompat.getDrawable(
                anchorView.getContext().getResources(), R.drawable.rewards_panel_background, null));

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            mPopupWindow.setElevation(1);
        }

        this.url = url;
        Log.e(TAG, "URL in primary constructor: " + this.url);

        setUpViews(deviceWidth);
    }

    // Secondary constructor without URL
    public RepSocialPanel(View anchorView, int deviceWidth) {
        this(anchorView, deviceWidth, "");
    }

    private void setUpViews(int deviceWidth) {
        Log.e(TAG, "URL in setUpViews: " + this.url);
        LayoutInflater inflater = (LayoutInflater) mAnchorView.getContext().getSystemService(
                Context.LAYOUT_INFLATER_SERVICE);
        mPopupView = inflater.inflate(R.layout.brave_rewards_rep_social_layout, null);
        modalWebView = (WebView) mPopupView.findViewById(R.id.modalWebView);

        // Configure WebView
        WebSettings webSettings = modalWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setUserAgentString(System.getProperty("http.agent"));

        CookieManager cookieManager = CookieManager.getInstance();
        cookieManager.setAcceptCookie(true);
        cookieManager.setAcceptThirdPartyCookies(modalWebView, true);
        modalWebView.setWebViewClient(new WebViewClient());

        Log.e(TAG, "URL before loading: " + this.url);

        // Load the URL if it's not empty
        if (this.url != null && !this.url.isEmpty()) {
            modalWebView.loadUrl("https://dev.rep.run?currentTabUrl=" + this.url);
        } else {
            modalWebView.loadUrl("https://dev.rep.run?currentTabUrl=new_tab");
        }

        mPopupWindow.setOnDismissListener(new PopupWindow.OnDismissListener() {
            @Override
            public void onDismiss() {
                if (mBraveRewardsNativeWorker != null) {
                    mBraveRewardsNativeWorker.removeObserver(RepSocialPanel.this);
                }
            }
        });

        mPopupWindow.setWidth(deviceWidth);
        mPopupWindow.setContentView(mPopupView);

        mBraveRewardsNativeWorker = BraveRewardsNativeWorker.getInstance();
        mBraveRewardsNativeWorker.addObserver(this);
    }

    public void showLikePopDownMenu() {
        mPopupWindow.setTouchable(true);
        mPopupWindow.setFocusable(true);
        mPopupWindow.setOutsideTouchable(true);
        mPopupWindow.showAsDropDown(mAnchorView, 0, 0);
    }

    private void showRewardsTour() {
        mPopupWindow.dismiss();
        TabUtils.openUrlInNewTab(false, BraveRewardsPanel.REWARDS_TOUR_URL);
    }
}
