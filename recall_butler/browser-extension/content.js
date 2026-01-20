// Recall Butler Browser Extension - Content Script

// Floating capture button
let captureButton = null;
let isVisible = false;

// Create floating button on selection
document.addEventListener('mouseup', (event) => {
  const selection = window.getSelection().toString().trim();
  
  if (selection.length > 10) {
    showCaptureButton(event.clientX, event.clientY, selection);
  } else {
    hideCaptureButton();
  }
});

// Hide button on click elsewhere
document.addEventListener('mousedown', (event) => {
  if (captureButton && !captureButton.contains(event.target)) {
    hideCaptureButton();
  }
});

// Create and show capture button
function showCaptureButton(x, y, selection) {
  if (!captureButton) {
    captureButton = document.createElement('div');
    captureButton.className = 'recall-butler-capture-btn';
    captureButton.innerHTML = `
      <span class="recall-butler-icon">🧠</span>
      <span class="recall-butler-text">Save to Butler</span>
    `;
    document.body.appendChild(captureButton);
    
    captureButton.addEventListener('click', async () => {
      captureButton.classList.add('loading');
      
      try {
        const response = await chrome.runtime.sendMessage({
          action: 'capture',
          data: {
            type: 'text',
            content: selection
          }
        });
        
        if (response.success) {
          showSuccessAnimation();
        } else {
          showErrorAnimation();
        }
      } catch (error) {
        console.error('Capture failed:', error);
        showErrorAnimation();
      }
      
      captureButton.classList.remove('loading');
      setTimeout(hideCaptureButton, 500);
    });
  }
  
  // Position the button
  const buttonWidth = 140;
  const buttonHeight = 36;
  const padding = 10;
  
  let posX = x + padding;
  let posY = y + padding;
  
  // Keep within viewport
  if (posX + buttonWidth > window.innerWidth) {
    posX = x - buttonWidth - padding;
  }
  if (posY + buttonHeight > window.innerHeight) {
    posY = y - buttonHeight - padding;
  }
  
  captureButton.style.left = `${posX}px`;
  captureButton.style.top = `${posY}px`;
  captureButton.classList.add('visible');
  isVisible = true;
}

// Hide capture button
function hideCaptureButton() {
  if (captureButton) {
    captureButton.classList.remove('visible');
    isVisible = false;
  }
}

// Success animation
function showSuccessAnimation() {
  if (captureButton) {
    captureButton.innerHTML = `
      <span class="recall-butler-icon">✓</span>
      <span class="recall-butler-text">Saved!</span>
    `;
    captureButton.classList.add('success');
  }
}

// Error animation
function showErrorAnimation() {
  if (captureButton) {
    captureButton.innerHTML = `
      <span class="recall-butler-icon">✕</span>
      <span class="recall-butler-text">Failed</span>
    `;
    captureButton.classList.add('error');
  }
}

// Listen for keyboard shortcut
document.addEventListener('keydown', (event) => {
  // Ctrl/Cmd + Shift + R for quick capture
  if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.key === 'R') {
    event.preventDefault();
    const selection = window.getSelection().toString().trim();
    
    if (selection) {
      chrome.runtime.sendMessage({
        action: 'capture',
        data: {
          type: 'text',
          content: selection
        }
      });
    } else {
      chrome.runtime.sendMessage({
        action: 'capture',
        data: {
          type: 'page'
        }
      });
    }
  }
});

// Highlight captured text temporarily
function highlightCapturedText() {
  const selection = window.getSelection();
  if (selection.rangeCount > 0) {
    const range = selection.getRangeAt(0);
    const highlight = document.createElement('span');
    highlight.className = 'recall-butler-highlight';
    
    try {
      range.surroundContents(highlight);
      setTimeout(() => {
        const parent = highlight.parentNode;
        while (highlight.firstChild) {
          parent.insertBefore(highlight.firstChild, highlight);
        }
        parent.removeChild(highlight);
      }, 2000);
    } catch (e) {
      // Can't highlight complex selections
    }
  }
}
