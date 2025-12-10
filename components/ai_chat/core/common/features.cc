/* Copyright (c) 2023 The Brave Authors. All rights reserved.
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at https://mozilla.org/MPL/2.0/. */

#include "brave/components/ai_chat/core/common/features.h"

#include <string>

#include "base/feature_list.h"
#include "base/metrics/field_trial_params.h"
#include "brave/components/ai_chat/core/common/buildflags/buildflags.h"
#include "brave/components/ai_chat/core/common/constants.h"
#include "build/build_config.h"

namespace ai_chat::features {

BASE_FEATURE(kAIChat, base::FEATURE_ENABLED_BY_DEFAULT);
const base::FeatureParam<std::string> kAIModelsDefaultKey{
#if BUILDFLAG(IS_IOS)
    &kAIChat, "default_model", "chat-basic"};
#else
    &kAIChat, "default_model", "chat-automatic"};
#endif
const base::FeatureParam<std::string> kAIModelsPremiumDefaultKey{
#if BUILDFLAG(IS_IOS)
    &kAIChat, "default_premium_model", kClaudeSonnetModelKey};
#else
    &kAIChat, "default_premium_model", "chat-automatic"};
#endif
const base::FeatureParam<std::string> kAIModelsVisionDefaultKey{
    &kAIChat, "default_vision_model", kClaudeHaikuModelKey};
const base::FeatureParam<std::string> kAIModelsPremiumVisionDefaultKey{
    &kAIChat, "default_vision_model", kClaudeSonnetModelKey};
const base::FeatureParam<bool> kFreemiumAvailable(&kAIChat,
                                                  "is_freemium_available",
                                                  true);
const base::FeatureParam<bool> kAIChatSSE{&kAIChat, "ai_chat_sse", true};
const base::FeatureParam<bool> kOmniboxOpensFullPage{
    &kAIChat, "omnibox_opens_full_page", true};
const base::FeatureParam<double> kAITemperature{&kAIChat, "temperature", 0.2};

const base::FeatureParam<size_t> kMaxCountLargeToolUseEvents{
    &kAIChat, "max_count_large_tool_use_events", 2};
const base::FeatureParam<size_t> kContentSizeLargeToolUseEvent{
    &kAIChat, "content_size_large_tool_use_events", 1000};

const base::FeatureParam<bool> kAutomaticModelSupportsTools{
    &kAIChat, "automatic_model_supports_tools", true};

const base::FeatureParam<bool> kShouldIndentPageContentBlocks{
    &kAIChat, "should_indent_page_content_blocks", true};

// ======= TẮT TOÀN BỘ AI CHAT TẠI ĐÂY =======

bool IsAIChatEnabled() {
  // Luôn tắt Leo / AI Chat
  return false;
}

BASE_FEATURE(kAIChatHistory,
#if BUILDFLAG(IS_IOS)
             base::FEATURE_DISABLED_BY_DEFAULT);
#else
             base::FEATURE_ENABLED_BY_DEFAULT);
#endif

bool IsAIChatHistoryEnabled() {
  // Tắt history
  return false;
}

BASE_FEATURE(kAIChatFirst, base::FEATURE_DISABLED_BY_DEFAULT);

bool IsAIChatFirstEnabled() {
  // Không cho hiện các onboarding / first-run AI chat
  return false;
}

BASE_FEATURE(kAIChatUserChoiceTool, base::FEATURE_DISABLED_BY_DEFAULT);

BASE_FEATURE(kAIChatAgentProfile,
             base::FEATURE_DISABLED_BY_DEFAULT);

bool IsAIChatAgentProfileEnabled() {
  // Dù buildflag có bật, mình vẫn muốn tắt
  return false;
}

BASE_FEATURE(kAIChatGlobalSidePanelEverywhere,
             base::FEATURE_DISABLED_BY_DEFAULT);

bool IsAIChatGlobalSidePanelEverywhereEnabled() {
  // Không cho side panel AI Chat dùng mọi nơi
  return false;
}

BASE_FEATURE(kCustomSiteDistillerScripts,
             base::FEATURE_ENABLED_BY_DEFAULT);

bool IsCustomSiteDistillerScriptsEnabled() {
  // Cái này không phải Leo trực tiếp, giữ nguyên logic gốc
  return base::FeatureList::IsEnabled(features::kCustomSiteDistillerScripts);
}

BASE_FEATURE(kContextMenuRewriteInPlace,
             "AIChatContextMenuRewriteInPlace",
             base::FEATURE_ENABLED_BY_DEFAULT);
bool IsContextMenuRewriteInPlaceEnabled() {
  // Nếu bạn muốn tắt hết AI liên quan context menu, cho false luôn:
  return false;
}

BASE_FEATURE(kAllowPrivateIPs,
             base::FEATURE_DISABLED_BY_DEFAULT);

bool IsAllowPrivateIPsEnabled() {
  return base::FeatureList::IsEnabled(features::kAllowPrivateIPs);
}

BASE_FEATURE(kOpenAIChatFromBraveSearch,
#if !BUILDFLAG(IS_ANDROID) && !BUILDFLAG(IS_IOS)
             base::FEATURE_ENABLED_BY_DEFAULT);
#else
             base::FEATURE_DISABLED_BY_DEFAULT);
#endif

bool IsOpenAIChatFromBraveSearchEnabled() {
  // Không cho Brave Search mở AI Chat
  return false;
}

BASE_FEATURE(kPageContextEnabledInitially,
             base::FEATURE_ENABLED_BY_DEFAULT);

bool IsPageContextEnabledInitially() {
  // Nếu muốn vô hiệu hoá luôn AI đọc nội dung trang thì cho false
  return false;
}

BASE_FEATURE(kTabOrganization,
             "BraveTabOrganization",
             base::FEATURE_ENABLED_BY_DEFAULT);

bool IsTabOrganizationEnabled() {
  // Nếu coi Tab Organization cũng là phần Leo/AI, thì tắt:
  return false;
}

BASE_FEATURE(kNEARModels,
             "AIChatNEARModels",
             base::FEATURE_DISABLED_BY_DEFAULT);

bool IsNEARModelsEnabled() {
  return false;
}

BASE_FEATURE(kRichSearchWidgets, base::FEATURE_DISABLED_BY_DEFAULT);

const base::FeatureParam<std::string> kRichSearchWidgetsOrigin{
    &kRichSearchWidgets, "rich_search_widgets_origin",
    "https://prod.browser-ai-includes.s.brave.app"};

}  // namespace ai_chat::features
