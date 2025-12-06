const button = document.getElementById("openSidePanel");
button.addEventListener("click", async () => {
  await chrome.sidePanel.open({
    windowId: (await chrome.windows.getCurrent()).id,
  });
});

chrome.runtime.sendMessage({ action: "refreshUI" }, function (response) {
  console.log(response);
});
