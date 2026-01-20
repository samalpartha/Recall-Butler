// Recall Butler Browser Extension - Background Service Worker

const API_BASE = 'http://localhost:8180';
const USER_ID = 1;

// Create context menu items on install
chrome.runtime.onInstalled.addListener(() => {
  // Context menu for selected text
  chrome.contextMenus.create({
    id: 'capture-selection',
    title: 'Save to Recall Butler',
    contexts: ['selection']
  });
  
  // Context menu for links
  chrome.contextMenus.create({
    id: 'capture-link',
    title: 'Save link to Recall Butler',
    contexts: ['link']
  });
  
  // Context menu for images
  chrome.contextMenus.create({
    id: 'capture-image',
    title: 'Save image to Recall Butler',
    contexts: ['image']
  });
  
  // Context menu for page
  chrome.contextMenus.create({
    id: 'capture-page',
    title: 'Save page to Recall Butler',
    contexts: ['page']
  });
  
  console.log('Recall Butler extension installed');
});

// Handle context menu clicks
chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  try {
    switch (info.menuItemId) {
      case 'capture-selection':
        await captureSelection(info.selectionText, tab);
        break;
      case 'capture-link':
        await captureLink(info.linkUrl, tab);
        break;
      case 'capture-image':
        await captureImage(info.srcUrl, tab);
        break;
      case 'capture-page':
        await capturePage(tab);
        break;
    }
  } catch (error) {
    console.error('Context menu action failed:', error);
    showNotification('Capture Failed', error.message, 'error');
  }
});

// Handle keyboard shortcuts
chrome.commands.onCommand.addListener(async (command) => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  
  try {
    switch (command) {
      case 'quick-capture':
        await capturePage(tab);
        break;
      case 'capture-selection':
        const [{ result }] = await chrome.scripting.executeScript({
          target: { tabId: tab.id },
          func: () => window.getSelection().toString().trim()
        });
        if (result) {
          await captureSelection(result, tab);
        } else {
          showNotification('No Selection', 'Please select some text first');
        }
        break;
    }
  } catch (error) {
    console.error('Command failed:', error);
    showNotification('Capture Failed', error.message, 'error');
  }
});

// Capture selected text
async function captureSelection(text, tab) {
  const response = await fetch(`${API_BASE}/api/document/createFromText`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: `Selection from ${new URL(tab.url).hostname}`,
      text: text,
      userId: USER_ID
    })
  });
  
  if (response.ok) {
    showNotification('Saved!', 'Selection captured to Recall Butler');
    await saveToRecent('selection', text.substring(0, 50), tab.url);
  } else {
    throw new Error('Failed to save selection');
  }
}

// Capture link
async function captureLink(url, tab) {
  const response = await fetch(`${API_BASE}/api/document/createFromUrl`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: `Link from ${new URL(tab.url).hostname}`,
      url: url,
      userId: USER_ID
    })
  });
  
  if (response.ok) {
    showNotification('Saved!', 'Link captured to Recall Butler');
    await saveToRecent('link', url, tab.url);
  } else {
    throw new Error('Failed to save link');
  }
}

// Capture image
async function captureImage(imageUrl, tab) {
  const response = await fetch(`${API_BASE}/api/document/createFromUrl`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: `Image from ${new URL(tab.url).hostname}`,
      url: imageUrl,
      userId: USER_ID
    })
  });
  
  if (response.ok) {
    showNotification('Saved!', 'Image captured to Recall Butler');
    await saveToRecent('image', imageUrl, tab.url);
  } else {
    throw new Error('Failed to save image');
  }
}

// Capture full page
async function capturePage(tab) {
  const response = await fetch(`${API_BASE}/api/document/createFromUrl`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: tab.title || 'Untitled Page',
      url: tab.url,
      userId: USER_ID
    })
  });
  
  if (response.ok) {
    showNotification('Saved!', 'Page captured to Recall Butler');
    await saveToRecent('page', tab.title, tab.url);
  } else {
    throw new Error('Failed to save page');
  }
}

// Save to recent captures
async function saveToRecent(type, title, url) {
  const { recentCaptures = [] } = await chrome.storage.local.get('recentCaptures');
  recentCaptures.unshift({
    type,
    title: title.substring(0, 100),
    url,
    timestamp: Date.now()
  });
  
  if (recentCaptures.length > 10) {
    recentCaptures.pop();
  }
  
  await chrome.storage.local.set({ recentCaptures });
}

// Show notification
function showNotification(title, message, type = 'success') {
  chrome.notifications.create({
    type: 'basic',
    iconUrl: 'icons/icon128.png',
    title: title,
    message: message,
    priority: type === 'error' ? 2 : 0
  });
}

// Listen for messages from content script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'capture') {
    handleCapture(message.data, sender.tab)
      .then(() => sendResponse({ success: true }))
      .catch(error => sendResponse({ success: false, error: error.message }));
    return true; // Keep channel open for async response
  }
});

async function handleCapture(data, tab) {
  switch (data.type) {
    case 'text':
      await captureSelection(data.content, tab);
      break;
    case 'url':
      await captureLink(data.content, tab);
      break;
    case 'page':
      await capturePage(tab);
      break;
    default:
      throw new Error('Unknown capture type');
  }
}
