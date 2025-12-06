/* eslint-disable no-prototype-builtins */
/* eslint-disable no-undef */

// Set the panel behavior to open on action click
chrome.sidePanel
  .setPanelBehavior({ openPanelOnActionClick: true })
  .catch((error) => console.error("Error setting panel behavior:", error));

/**
 * This listener is triggered when the extension is installed or updated.
 * Creates a context menu item and opens the initial page.
 * Documentation: https://developer.chrome.com/docs/extensions/reference/runtime/#event-onInstalled
 */
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "openSidePanel",
    title: "OpenRep Social Side Panel",
    contexts: ["all"],
  });

  chrome.tabs.create({ url: "page.html" });
});

/**
 * This listener is triggered when a context menu item is clicked.
 * Opens the side panel in all pages of the current window.
 * Documentation: https://developer.chrome.com/docs/extensions/reference/contextMenus/#event-onClicked
 */
chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "openSidePanel") {
    chrome.sidePanel
      .open({ windowId: tab.windowId })
      .catch((error) => console.error("Error opening side panel:", error));
  }
});

const callMap = new Set();
/**
 * This listener is triggered when a message is sent from another part of the extension.
 * Handles different types of messages including opening the side panel and redirecting URLs.
 * Documentation: https://developer.chrome.com/docs/extensions/reference/runtime/#event-onMessage
 */
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  (async () => {
    if (message.type === "open_side_panel") {
      try {
        await chrome.sidePanel.open({ tabId: sender.tab.id });
        await chrome.sidePanel.setOptions({
          tabId: sender.tab.id,
          path: "index.html",
          enabled: true,
        });
      } catch (error) {
        console.error("Error handling open_side_panel message:", error);
      }
    }
    if (message.action === "social-login") {
      const response = await firebaseAuth(message.data);
      sendResponse(response);
    } else {
      chrome.runtime.sendMessage({
        action: message.action,
        data: message.data,
      });
    }
  })();

  if (message.action === "redirect") {
    const newUrl = message.newUrl;
    if (newUrl) {
      chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
        let activeTab = tabs[0];
        chrome.tabs
          .update(activeTab.id, { url: newUrl })
          .catch((error) => console.error("Error updating tab URL:", error));
      });
    }
  }

  if (message.action === "openNewTab") {
    console.log("message", message);

    const newUrl = message.newUrl;
    const isOpenCallTab = newUrl.startsWith(
      "https://video-call-sdk-ui.vercel.app/room/"
    );

    if (newUrl && !callMap.has(newUrl)) {
      chrome.tabs.create({ url: newUrl, active: true });

      if (isOpenCallTab) {
        callMap.add(newUrl);
        setTimeout(() => {
          callMap.delete(newUrl);
        }, 1000);
      }
    }
  }

  if (message === "getTabUrl") {
    chrome.tabs.query({ active: true, currentWindow: true }, function (tabs) {
      let currentTab = tabs[0];
      let currentUrl = currentTab.url;
      sendResponse({ url: currentUrl });
    });
  }

  return true; // Indicate that sendResponse will be called asynchronously
});

/**
 * This listener is triggered when a message is sent from another extension or web page.
 * Handles storing tokens and performing KYC verification.
 * Documentation: https://developer.chrome.com/docs/extensions/reference/runtime/#event-onMessageExternal
 */
chrome.runtime.onMessageExternal.addListener(
  (message, sender, sendResponse) => {
    console.log("Received external message:", message);

    if (message.token) {
      const data = message.token;
      for (const key in data) {
        if (data.hasOwnProperty(key)) {
          let item = {};
          item[key] = data[key];
          chrome.storage.local.set(item, () => {
            if (chrome.runtime.lastError) {
              console.error(`Error setting ${key}:`, chrome.runtime.lastError);
            } else {
              console.log(`${key} saved successfully.`);
            }
          });
        }
      }

      sendResponse({ success: true });

      chrome.tabs.create(
        { url: "chrome-extension://" + chrome.runtime.id + "/page.html" },
        () => {
          sendResponse({ success: true });
        }
      );
    } else {
      sendResponse({ success: false });
    }

    // redirect message from content.js to rep extension
    if (message.action === "startLoadingRepIframe") {
      chrome.runtime.sendMessage({
        action: "startLoadingRepIframe",
      });
    }

    if (message.action === "repEmbedded") {
      chrome.runtime.sendMessage({
        action: "repEmbedded",
      });
    }
  }
);

/**
 * This listener is triggered when the active tab in a window changes.
 * Sends a message with the details of the activated tab.
 * Documentation: https://developer.chrome.com/docs/extensions/reference/tabs/#event-onActivated
 */
chrome.tabs.onActivated.addListener((activeInfo) => {
  chrome.tabs.get(activeInfo.tabId, (tab) => {
    chrome.runtime.sendMessage({
      action: "tabActivated",
      tab,
      windowId: tab.windowId,
    });
  });
});

/**
 * Listener for window focus changes in Chrome.
 */
chrome.windows.onFocusChanged.addListener((windowId) => {
  // Ignore if no window is focused
  if (windowId === chrome.windows.WINDOW_ID_NONE) return;

  // Query the active tab in the focused window
  chrome.tabs.query({ active: true, windowId }, (tabs) => {
    if (tabs.length > 0) {
      tabs.forEach((activeTab) => {
        chrome.runtime.sendMessage({
          action: "tabActivated",
          tab: activeTab,
          windowId: activeTab.windowId,
        });
      });
    }
  });
});

/**
 * This listener is triggered when a tab is updated.
 * Sends a message with the updated tab's URL.
 * Documentation: https://developer.chrome.com/docs/extensions/reference/tabs/#event-onUpdated
 */
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.url) {
    chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
      tabs.forEach((activeTab) => {
        chrome.runtime.sendMessage({
          action: "tabActivated",
          tab: activeTab,
          windowId: activeTab.windowId,
        });
      });
    });
  }

  if (
    tab.url.startsWith("https://accounts.google.com/o/oauth2/auth/") ||
    tab.url.startsWith("https://repdevelop-283fb.firebaseapp.com") ||
    tab.url.startsWith("https://id.worldcoin.org/login") ||
    tab.url.startsWith("https://www.linkedin.com/uas/login")
  ) {
    chrome.windows.update(tab.windowId, { focused: true });
    return;
  }
});

const OFFSCREEN_DOCUMENT_PATH = "/offscreen.html";

// A global promise to avoid concurrency issues
let creatingOffscreenDocument;

// Chrome only allows for a single offscreenDocument. This is a helper function
// that returns a boolean indicating if a document is already active.
async function hasDocument() {
  // Check all windows controlled by the service worker to see if one
  // of them is the offscreen document with the given path
  const matchedClients = await clients.matchAll();
  return matchedClients.some(
    (c) => c.url === chrome.runtime.getURL(OFFSCREEN_DOCUMENT_PATH)
  );
}

async function setupOffscreenDocument(path) {
  const hasDoc = await hasDocument();
  console.log("hasDoc", hasDoc);
  if (!hasDoc) {
    if (typeof creating !== "undefined" && !!creating) {
      await creating;
      creating = null;
    } else {
      creating = chrome.offscreen.createDocument({
        url: path,
        reasons: [chrome.offscreen.Reason.DOM_SCRAPING],
        justification: "authentication",
      });

      // await offscreen loading;
      // await new Promise((res) => {
      //   setTimeout(() => {
      //     res(true);
      //   }, [500]);
      // });
      await creating;
      creating = null;
    }
  }
}

async function closeOffscreenDocument() {
  console.log("closeOffscreenDocument");
  if (!(await hasDocument())) {
    return;
  }
  await chrome.offscreen.closeDocument();
}

function getAuth(type) {
  return new Promise((resolve, reject) => {
    console.log("getAuth", type);
    chrome.runtime.sendMessage(
      {
        type: "firebase-auth",
        target: "offscreen",
        value: type,
      },
      (auth) => {
        auth?.name !== "FirebaseError" ? resolve(auth) : reject(auth);
      }
    );
  });
}

async function firebaseAuth(type) {
  await setupOffscreenDocument(OFFSCREEN_DOCUMENT_PATH);

  const auth = await getAuth(type)
    .then((auth) => {
      return auth;
    })
    .catch((err) => {
      if (err.code === "auth/operation-not-allowed") {
        console.error(
          "You must enable an OAuth provider in the Firebase" +
            " console in order to use signInWithPopup. This sample" +
            " uses Google by default."
        );
      } else {
        console.error(err);
        return err;
      }
    })
    .finally(closeOffscreenDocument);

  return auth;
}
