/**
 * Copyright (c) 2023 The Brave Authors.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/.
 */

package org.chromium.chrome.browser.rewards.onboarding;

import android.annotation.TargetApi;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.PopupWindow;

import androidx.core.content.res.ResourcesCompat;

import org.chromium.chrome.R;
import org.chromium.chrome.browser.rewards.BraveRewardsPanel;
import org.chromium.chrome.browser.util.TabUtils;

/**
 * This class is used to show rewards onboarding UI
 **/
public class RepSocialPanel {
    private static final String TAG = "RepSocialPanel";

    private final View mAnchorView;
    private final PopupWindow mPopupWindow;
    private View mPopupView;
    private WebView modalWebView;

    private String mUrl = "";

    // Primary constructor with URL
    public RepSocialPanel(View anchorView, int deviceWidth, String url) {
        mAnchorView = anchorView;
        mPopupWindow = new PopupWindow(anchorView.getContext());
        mPopupWindow.setHeight(ViewGroup.LayoutParams.WRAP_CONTENT);
        mPopupWindow.setBackgroundDrawable(
                ResourcesCompat.getDrawable(
                        anchorView.getContext().getResources(),
                        R.drawable.rewards_panel_background,
                        null));

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            mPopupWindow.setElevation(1);
        }

        this.mUrl = url;
        Log.e(TAG, "URL in primary constructor: " + mUrl);

        setUpViews(deviceWidth);
    }

    // Secondary constructor without URL
    public RepSocialPanel(View anchorView, int deviceWidth) {
        this(anchorView, deviceWidth, "");
    }

    private void setUpViews(int deviceWidth) {
        Log.e(TAG, "URL in setUpViews: " + mUrl);

        LayoutInflater inflater = (LayoutInflater)
                mAnchorView.getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        mPopupView = inflater.inflate(R.layout.brave_rewards_rep_social_layout, null);
        modalWebView = mPopupView.findViewById(R.id.modalWebView);


        WebSettings webSettings = modalWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setCacheMode(WebSettings.LOAD_NO_CACHE);
        webSettings.setAllowFileAccess(false); 
        webSettings.setAllowContentAccess(false);
        webSettings.setUserAgentString(System.getProperty("http.agent"));

        modalWebView.setWebChromeClient(new WebChromeClient());
        modalWebView.setWebViewClient(new WebViewClient() {
            // API >= 24
            @TargetApi(Build.VERSION_CODES.N)
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return handleUrlOpenNewTab(request.getUrl().toString());
            }

        
            @SuppressWarnings("deprecation")
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return handleUrlOpenNewTab(url);
            }

            @Override
            public void onPageFinished(WebView view, String url) {
                Log.e(TAG, "Page loaded: " + url);
            }

            @Override
            public void onReceivedError(WebView view, int errorCode,
                                        String description, String failingUrl) {
                Log.e(TAG, "Error loading page: " + description);
            }
        });

        CookieManager cookieManager = CookieManager.getInstance();
        cookieManager.setAcceptCookie(true);
        cookieManager.setAcceptThirdPartyCookies(modalWebView, true);

        Log.e(TAG, "URL before loading: " + mUrl);

       String targetUrl = (mUrl != null && !mUrl.isEmpty())
                ? "https://staging.rep.run?currentTabUrl=" + mUrl
                : "https://staging.rep.run?currentTabUrl=new_tab";
                
        modalWebView.loadUrl(targetUrl);

        mPopupWindow.setOnDismissListener(() -> {
            Log.e(TAG, "Popup dismissed");
        });

        mPopupWindow.setWidth(deviceWidth);
        mPopupWindow.setContentView(mPopupView);
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

    private boolean handleUrlOpenNewTab(String url) {
        try {
            Uri uri = Uri.parse(url);
            String typeValue = uri.getQueryParameter("type");

            if ("openNewTab".equals(typeValue)) {
                Uri.Builder builder = uri.buildUpon();
                builder.clearQuery();
                for (String paramName : uri.getQueryParameterNames()) {
                    if (!"type".equals(paramName)) {
                        builder.appendQueryParameter(paramName, uri.getQueryParameter(paramName));
                    }
                }

                String newUrl = builder.build().toString();
                Log.e(TAG, "Open new tab with: " + newUrl);

                TabUtils.openUrlInNewTab(false, newUrl);
                mPopupWindow.dismiss();
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}
