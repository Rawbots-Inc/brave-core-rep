function isCurrentSiteRepEmbedded() {
  const repIframe = document.getElementById("rep-iframe");
  return (
    repIframe && repIframe.nodeName === "IFRAME"
    // [
    //   "https://staging.rep.run",
    //   "https://dev.rep.run",
    //   "https://rep.run",
    // ].includes(repIframe.getAttribute("src"))
  );
}

/* eslint-disable no-undef */
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === "repEmbedded") {
    sendResponse({
      isRepEmbedded: isCurrentSiteRepEmbedded(),
    });
  }
});

if (isCurrentSiteRepEmbedded()) {
  chrome.runtime.sendMessage({
    action: "repEmbedded",
    data: {
      closeExtension: true
    }
  });
}

// Receive this message from current site if it embed rep iframe
window.addEventListener("message", function (event) {
  const { action, data } = event.data;

  if (action === "startLoadingRepIframe") {
    // redirect message to background.js
    chrome.runtime.sendMessage({
      action: "startLoadingRepIframe",
    });
  } else {
    chrome.runtime.sendMessage({
      action: action,
      data,
    });
  }
});
