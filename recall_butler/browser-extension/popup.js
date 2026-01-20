// Recall Butler Browser Extension - Popup Script

const API_BASE = 'http://localhost:8180';
const USER_ID = 1; // Default user ID

// DOM Elements
const connectionStatus = document.getElementById('connectionStatus');
const capturePageBtn = document.getElementById('capturePageBtn');
const captureSelectionBtn = document.getElementById('captureSelectionBtn');
const titleInput = document.getElementById('titleInput');
const noteInput = document.getElementById('noteInput');
const saveNoteBtn = document.getElementById('saveNoteBtn');
const recentCaptures = document.getElementById('recentCaptures');
const toast = document.getElementById('toast');
const settingsBtn = document.getElementById('settingsBtn');

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
  await checkConnection();
  await loadRecentCaptures();
  setupEventListeners();
  checkForSelection();
});

// Check API connection
async function checkConnection() {
  try {
    const response = await fetch(`${API_BASE}/`, { method: 'GET' });
    if (response.ok) {
      connectionStatus.classList.add('connected');
      connectionStatus.classList.remove('disconnected');
      connectionStatus.querySelector('.status-text').textContent = 'Connected to Recall Butler';
    } else {
      throw new Error('Server not responding');
    }
  } catch (error) {
    connectionStatus.classList.add('disconnected');
    connectionStatus.classList.remove('connected');
    connectionStatus.querySelector('.status-text').textContent = 'Not connected - Start the server';
  }
}

// Setup event listeners
function setupEventListeners() {
  capturePageBtn.addEventListener('click', capturePage);
  captureSelectionBtn.addEventListener('click', captureSelection);
  saveNoteBtn.addEventListener('click', saveNote);
  settingsBtn.addEventListener('click', openSettings);
}

// Check if there's selected text on the page
async function checkForSelection() {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    const [{ result }] = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => window.getSelection().toString().trim()
    });
    
    if (result && result.length > 0) {
      captureSelectionBtn.disabled = false;
      captureSelectionBtn.querySelector('span').textContent = `Capture Selection (${result.length} chars)`;
    }
  } catch (error) {
    console.log('Could not check selection:', error);
  }
}

// Capture current page
async function capturePage() {
  capturePageBtn.classList.add('loading');
  
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    
    // Get page content
    const [{ result }] = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: extractPageContent
    });
    
    // Send to API
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
      showToast('Page captured successfully!');
      await saveToRecent({
        type: 'page',
        title: tab.title,
        url: tab.url,
        timestamp: Date.now()
      });
      await loadRecentCaptures();
    } else {
      throw new Error('Failed to save');
    }
  } catch (error) {
    showToast('Failed to capture page', true);
    console.error('Capture error:', error);
  } finally {
    capturePageBtn.classList.remove('loading');
  }
}

// Capture selected text
async function captureSelection() {
  captureSelectionBtn.classList.add('loading');
  
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    
    // Get selection
    const [{ result: selection }] = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: () => window.getSelection().toString().trim()
    });
    
    if (!selection) {
      showToast('No text selected', true);
      return;
    }
    
    // Send to API
    const response = await fetch(`${API_BASE}/api/document/createFromText`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: `Selection from ${new URL(tab.url).hostname}`,
        text: selection,
        userId: USER_ID
      })
    });
    
    if (response.ok) {
      showToast('Selection captured!');
      await saveToRecent({
        type: 'selection',
        title: selection.substring(0, 50) + (selection.length > 50 ? '...' : ''),
        url: tab.url,
        timestamp: Date.now()
      });
      await loadRecentCaptures();
    } else {
      throw new Error('Failed to save');
    }
  } catch (error) {
    showToast('Failed to capture selection', true);
    console.error('Selection error:', error);
  } finally {
    captureSelectionBtn.classList.remove('loading');
  }
}

// Save custom note
async function saveNote() {
  const title = titleInput.value.trim() || 'Quick Note';
  const note = noteInput.value.trim();
  
  if (!note) {
    showToast('Please enter a note', true);
    return;
  }
  
  saveNoteBtn.classList.add('loading');
  
  try {
    const response = await fetch(`${API_BASE}/api/document/createFromText`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: title,
        text: note,
        userId: USER_ID
      })
    });
    
    if (response.ok) {
      showToast('Note saved!');
      titleInput.value = '';
      noteInput.value = '';
      await saveToRecent({
        type: 'note',
        title: title,
        timestamp: Date.now()
      });
      await loadRecentCaptures();
    } else {
      throw new Error('Failed to save');
    }
  } catch (error) {
    showToast('Failed to save note', true);
    console.error('Note error:', error);
  } finally {
    saveNoteBtn.classList.remove('loading');
  }
}

// Extract page content (runs in page context)
function extractPageContent() {
  const article = document.querySelector('article') || document.body;
  
  // Get main text content
  const textContent = article.innerText
    .replace(/\s+/g, ' ')
    .trim()
    .substring(0, 10000); // Limit to 10k chars
  
  // Get metadata
  const meta = {
    title: document.title,
    description: document.querySelector('meta[name="description"]')?.content || '',
    author: document.querySelector('meta[name="author"]')?.content || '',
    publishedDate: document.querySelector('meta[property="article:published_time"]')?.content || ''
  };
  
  return { textContent, meta };
}

// Save to recent captures (local storage)
async function saveToRecent(capture) {
  const { recentCaptures = [] } = await chrome.storage.local.get('recentCaptures');
  recentCaptures.unshift(capture);
  
  // Keep only last 10
  if (recentCaptures.length > 10) {
    recentCaptures.pop();
  }
  
  await chrome.storage.local.set({ recentCaptures });
}

// Load recent captures
async function loadRecentCaptures() {
  const { recentCaptures: captures = [] } = await chrome.storage.local.get('recentCaptures');
  
  if (captures.length === 0) {
    recentCaptures.innerHTML = '<div class="empty-state"><span>No recent captures</span></div>';
    return;
  }
  
  recentCaptures.innerHTML = captures.map(capture => {
    const icon = capture.type === 'page' ? '📄' : capture.type === 'selection' ? '✂️' : '📝';
    const timeAgo = getTimeAgo(capture.timestamp);
    
    return `
      <div class="recent-item" data-url="${capture.url || ''}">
        <div class="recent-item-icon">${icon}</div>
        <div class="recent-item-content">
          <div class="recent-item-title">${escapeHtml(capture.title)}</div>
          <div class="recent-item-meta">${timeAgo}</div>
        </div>
      </div>
    `;
  }).join('');
  
  // Add click handlers
  recentCaptures.querySelectorAll('.recent-item[data-url]').forEach(item => {
    item.addEventListener('click', () => {
      const url = item.dataset.url;
      if (url) {
        chrome.tabs.create({ url });
      }
    });
  });
}

// Show toast notification
function showToast(message, isError = false) {
  toast.classList.remove('hidden', 'error');
  if (isError) toast.classList.add('error');
  toast.querySelector('.toast-icon').textContent = isError ? '✕' : '✓';
  toast.querySelector('.toast-message').textContent = message;
  
  setTimeout(() => {
    toast.classList.add('hidden');
  }, 3000);
}

// Open settings
function openSettings() {
  chrome.runtime.openOptionsPage();
}

// Helper: Get time ago string
function getTimeAgo(timestamp) {
  const seconds = Math.floor((Date.now() - timestamp) / 1000);
  
  if (seconds < 60) return 'Just now';
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
  return `${Math.floor(seconds / 86400)}d ago`;
}

// Helper: Escape HTML
function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
