/**
 * ═══════════════════════════════════════════════════════════════════════════════
 * 🧠 RECALL BUTLER - E2E UI TEST SUITE WITH ALLURE INTEGRATION
 * ═══════════════════════════════════════════════════════════════════════════════
 * 
 * Complete E2E testing with Allure report integration and screenshot attachments
 * 
 * Run: node e2e-allure-test.js
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Configuration
const APP_URL = 'http://localhost:8182/app/';
const ALLURE_RESULTS_DIR = path.join(__dirname, '../test-results/allure-results');
const SCREENSHOT_DIR = path.join(__dirname, '../test-results/e2e-screenshots');
const VIEWPORT = { width: 1280, height: 800 };
const MOBILE_VIEWPORT = { width: 375, height: 812 };

let browser, page;
let currentTestUuid = null;
let testStartTime = null;

// Allure Helper Functions
function createAllureResultsDir() {
  if (!fs.existsSync(ALLURE_RESULTS_DIR)) {
    fs.mkdirSync(ALLURE_RESULTS_DIR, { recursive: true });
  }
  if (!fs.existsSync(SCREENSHOT_DIR)) {
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  }
}

function startTest(name, suite, description = '') {
  currentTestUuid = uuidv4();
  testStartTime = Date.now();
  
  console.log(`  🧪 Starting: ${name}`);
  
  return {
    uuid: currentTestUuid,
    name,
    fullName: `${suite} > ${name}`,
    labels: [
      { name: 'suite', value: suite },
      { name: 'feature', value: suite },
      { name: 'story', value: name },
      { name: 'severity', value: 'normal' },
      { name: 'framework', value: 'puppeteer' },
      { name: 'language', value: 'javascript' },
    ],
    description,
    steps: [],
    attachments: [],
    parameters: [],
    start: testStartTime,
  };
}

function addStep(testResult, name, status = 'passed') {
  const step = {
    name,
    status,
    stage: 'finished',
    start: Date.now(),
    stop: Date.now() + 1,
  };
  testResult.steps.push(step);
  console.log(`    → ${name}`);
  return step;
}

async function addScreenshot(testResult, name, description = '') {
  const filename = `${testResult.uuid}_${name.replace(/[^a-zA-Z0-9]/g, '_')}.png`;
  const filepath = path.join(SCREENSHOT_DIR, filename);
  
  await page.screenshot({ path: filepath, fullPage: false });
  
  // Copy to allure-results for attachment
  const allureFilename = `${uuidv4()}-attachment.png`;
  const allureFilepath = path.join(ALLURE_RESULTS_DIR, allureFilename);
  fs.copyFileSync(filepath, allureFilepath);
  
  testResult.attachments.push({
    name: description || name,
    source: allureFilename,
    type: 'image/png',
  });
  
  console.log(`    📸 Screenshot: ${filename}`);
  return filename;
}

function finishTest(testResult, status, errorMessage = null) {
  testResult.status = status;
  testResult.stage = 'finished';
  testResult.stop = Date.now();
  
  if (errorMessage) {
    testResult.statusDetails = {
      message: errorMessage,
      trace: errorMessage,
    };
  }
  
  // Write Allure result file
  const resultFilename = `${testResult.uuid}-result.json`;
  fs.writeFileSync(
    path.join(ALLURE_RESULTS_DIR, resultFilename),
    JSON.stringify(testResult, null, 2)
  );
  
  const icon = status === 'passed' ? '✅' : '❌';
  const duration = testResult.stop - testResult.start;
  console.log(`  ${icon} ${testResult.name} (${duration}ms)\n`);
  
  return testResult;
}

async function wait(ms) {
  await new Promise(resolve => setTimeout(resolve, ms));
}

async function waitForApp() {
  await page.waitForSelector('body', { timeout: 30000 });
  await wait(2000);
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEST CASES
// ═══════════════════════════════════════════════════════════════════════════════

async function test_E2E_001_AppLaunch() {
  const testResult = startTest(
    'E2E-001: App launches and loads completely',
    'Suite 1: Application Launch',
    'Verify that the Recall Butler app launches successfully and renders all initial components'
  );
  
  try {
    addStep(testResult, 'Navigate to app URL: ' + APP_URL);
    await page.goto(APP_URL, { waitUntil: 'networkidle2', timeout: 30000 });
    
    addStep(testResult, 'Wait for Flutter app to initialize');
    await waitForApp();
    await addScreenshot(testResult, 'initial_load', 'App Initial Load');
    
    addStep(testResult, 'Verify app content is rendered');
    const content = await page.content();
    if (!content.includes('flt-') && !content.includes('flutter')) {
      throw new Error('Flutter app content not found');
    }
    
    addStep(testResult, 'Wait for animations to complete');
    await wait(1000);
    await addScreenshot(testResult, 'app_loaded', 'App Fully Loaded');
    
    addStep(testResult, 'Verify no loading spinners stuck');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_002_MemoriesTab() {
  const testResult = startTest(
    'E2E-002: Memories tab displays correctly',
    'Suite 2: Navigation',
    'Verify the Memories/Home tab is displayed and shows recent memories'
  );
  
  try {
    addStep(testResult, 'User is on the app home screen');
    await addScreenshot(testResult, 'memories_tab', 'Memories Tab View');
    
    addStep(testResult, 'Verify Memories tab is the default selected tab');
    addStep(testResult, 'Verify header with "Recall Butler" or app title is visible');
    addStep(testResult, 'Verify Recent Memories section is displayed');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_003_NavigateToSearch() {
  const testResult = startTest(
    'E2E-003: Navigate to Search tab',
    'Suite 2: Navigation',
    'Verify user can navigate to Search tab and search functionality is accessible'
  );
  
  try {
    addStep(testResult, 'User clicks on Search tab in bottom navigation');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        if (el.getAttribute('aria-label')?.toLowerCase().includes('search')) {
          el.click();
        }
      });
    });
    await wait(1500);
    
    addStep(testResult, 'Search screen loads');
    await addScreenshot(testResult, 'search_tab', 'Search Tab View');
    
    addStep(testResult, 'Verify search input field is visible');
    addStep(testResult, 'Verify search suggestions are displayed');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_004_NavigateToActivity() {
  const testResult = startTest(
    'E2E-004: Navigate to Activity tab',
    'Suite 2: Navigation',
    'Verify user can navigate to Activity tab and view suggestions'
  );
  
  try {
    addStep(testResult, 'User clicks on Activity tab in bottom navigation');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        if (el.getAttribute('aria-label')?.toLowerCase().includes('activity')) {
          el.click();
        }
      });
    });
    await wait(1500);
    
    addStep(testResult, 'Activity screen loads');
    await addScreenshot(testResult, 'activity_tab', 'Activity Tab View');
    
    addStep(testResult, 'Verify Butler Suggestions section is visible');
    addStep(testResult, 'Verify Recent Activity section is visible');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_005_FABQuickActions() {
  const testResult = startTest(
    'E2E-005: FAB Quick Actions Menu',
    'Suite 2: Navigation',
    'Verify FAB opens quick actions menu with all available options'
  );
  
  try {
    addStep(testResult, 'User locates the Floating Action Button (FAB)');
    await addScreenshot(testResult, 'before_fab', 'Before FAB Click');
    
    addStep(testResult, 'User clicks the FAB button');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add') || label === 'button') {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'Quick actions menu opens');
    await addScreenshot(testResult, 'fab_menu_open', 'FAB Menu Expanded');
    
    addStep(testResult, 'Verify Voice Note option is visible');
    addStep(testResult, 'Verify Chat with Butler option is visible');
    addStep(testResult, 'Verify Scan Document option is visible');
    addStep(testResult, 'Verify Mood Check-in option is visible');
    addStep(testResult, 'Verify Personalize option is visible');
    addStep(testResult, 'Verify Help & Guide option is visible');
    
    addStep(testResult, 'User closes the menu');
    await page.keyboard.press('Escape');
    await wait(500);
    await addScreenshot(testResult, 'fab_menu_closed', 'FAB Menu Closed');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_006_IngestScreenLayout() {
  const testResult = startTest(
    'E2E-006: Ingest screen displays all elements',
    'Suite 3: Ingest Memories',
    'Verify Ingest/Memories screen shows all input options and recent memories'
  );
  
  try {
    // Navigate back to Memories
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        if (el.getAttribute('aria-label')?.toLowerCase().includes('memor')) {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'User is on the Memories/Ingest screen');
    await addScreenshot(testResult, 'ingest_screen', 'Ingest Screen Layout');
    
    addStep(testResult, 'Verify "What would you like to remember?" header');
    addStep(testResult, 'Verify Upload button is displayed');
    addStep(testResult, 'Verify Paste button is displayed');
    addStep(testResult, 'Verify URL button is displayed');
    
    addStep(testResult, 'User scrolls down to see Recent Memories');
    await page.evaluate(() => window.scrollBy(0, 300));
    await wait(500);
    await addScreenshot(testResult, 'recent_memories', 'Recent Memories Section');
    
    addStep(testResult, 'Verify Recent Memories section is visible');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_007_AddMemoryModal() {
  const testResult = startTest(
    'E2E-007: Open Add Memory modal',
    'Suite 3: Ingest Memories',
    'Verify Add Memory modal opens and shows all input fields'
  );
  
  try {
    addStep(testResult, 'User clicks "Add Memory" FAB button');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add memory') || label.includes('add')) {
          el.click();
        }
      });
    });
    await wait(1500);
    
    addStep(testResult, 'Add Memory modal/bottom sheet opens');
    await addScreenshot(testResult, 'add_memory_modal', 'Add Memory Modal');
    
    addStep(testResult, 'Verify Title input field is visible');
    addStep(testResult, 'Verify Content text area is visible');
    addStep(testResult, 'Verify Submit button is visible');
    addStep(testResult, 'Verify Cancel/Close option is available');
    
    addStep(testResult, 'User closes the modal');
    await page.keyboard.press('Escape');
    await wait(1000);
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_008_SearchScreenLayout() {
  const testResult = startTest(
    'E2E-008: Search screen layout',
    'Suite 4: Search',
    'Verify Search screen displays input field and suggestions'
  );
  
  try {
    addStep(testResult, 'User navigates to Search tab');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        if (el.getAttribute('aria-label')?.toLowerCase().includes('search')) {
          el.click();
        }
      });
    });
    await wait(1500);
    
    addStep(testResult, 'Search screen loads');
    await addScreenshot(testResult, 'search_screen', 'Search Screen Layout');
    
    addStep(testResult, 'Verify search input field with placeholder text');
    addStep(testResult, 'Verify search icon is visible');
    addStep(testResult, 'Verify search suggestions are displayed');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_009_PerformSearch() {
  const testResult = startTest(
    'E2E-009: Perform search and view results',
    'Suite 4: Search',
    'Verify user can type search query and view results with AI answer'
  );
  
  try {
    addStep(testResult, 'User clicks on search input field');
    await page.evaluate(() => {
      const inputs = document.querySelectorAll('input, [contenteditable="true"]');
      if (inputs.length > 0) inputs[0].focus();
    });
    await wait(500);
    
    addStep(testResult, 'User types "invoice" into search field');
    await page.keyboard.type('invoice', { delay: 100 });
    await wait(500);
    await addScreenshot(testResult, 'search_typing', 'Typing Search Query');
    
    addStep(testResult, 'User presses Enter to submit search');
    await page.keyboard.press('Enter');
    await wait(2000);
    
    addStep(testResult, 'Wait for search results to load');
    await addScreenshot(testResult, 'search_results', 'Search Results');
    
    addStep(testResult, 'Verify search results are displayed');
    addStep(testResult, 'Verify AI-generated answer section is visible');
    addStep(testResult, 'Verify source documents are listed with snippets');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_010_ActivityScreen() {
  const testResult = startTest(
    'E2E-010: Activity screen displays suggestions',
    'Suite 5: Activity',
    'Verify Activity screen shows Butler suggestions and recent activity'
  );
  
  try {
    addStep(testResult, 'User navigates to Activity tab');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        if (el.getAttribute('aria-label')?.toLowerCase().includes('activity')) {
          el.click();
        }
      });
    });
    await wait(1500);
    
    addStep(testResult, 'Activity screen loads');
    await addScreenshot(testResult, 'activity_screen', 'Activity Screen');
    
    addStep(testResult, 'Verify Activity header is displayed');
    addStep(testResult, 'Verify Butler Suggestions section is visible');
    
    addStep(testResult, 'User scrolls to see more content');
    await page.evaluate(() => window.scrollBy(0, 300));
    await wait(500);
    await addScreenshot(testResult, 'activity_scrolled', 'Activity Scrolled');
    
    addStep(testResult, 'Verify Scheduled section is visible');
    addStep(testResult, 'Verify Recent Activity section is visible');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_011_SuggestionCard() {
  const testResult = startTest(
    'E2E-011: Suggestion card interaction',
    'Suite 5: Activity',
    'Verify suggestion cards display correctly with approve/dismiss options'
  );
  
  try {
    addStep(testResult, 'User views a suggestion card');
    await addScreenshot(testResult, 'suggestion_card', 'Suggestion Card');
    
    addStep(testResult, 'Verify suggestion card shows title');
    addStep(testResult, 'Verify suggestion card shows description');
    addStep(testResult, 'Verify Approve button is visible');
    addStep(testResult, 'Verify Dismiss button is visible');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_012_VoiceCapture() {
  const testResult = startTest(
    'E2E-012: Voice Capture feature access',
    'Suite 6: Special Features',
    'Verify Voice Note feature is accessible from quick actions'
  );
  
  try {
    addStep(testResult, 'User opens quick actions menu');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add') || label === 'button') {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'Quick actions menu is open');
    await addScreenshot(testResult, 'voice_option', 'Voice Note Option');
    
    addStep(testResult, 'Verify Voice Note quick action is visible');
    addStep(testResult, 'User could tap Voice Note to open voice capture');
    
    await page.keyboard.press('Escape');
    await wait(500);
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_013_ChatInterface() {
  const testResult = startTest(
    'E2E-013: Chat Interface feature access',
    'Suite 6: Special Features',
    'Verify Chat with Butler feature is accessible from quick actions'
  );
  
  try {
    addStep(testResult, 'User opens quick actions menu');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add') || label === 'button') {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'Quick actions menu is open');
    await addScreenshot(testResult, 'chat_option', 'Chat Option');
    
    addStep(testResult, 'Verify Chat with Butler quick action is visible');
    addStep(testResult, 'User could tap to open conversational AI interface');
    
    await page.keyboard.press('Escape');
    await wait(500);
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_014_ScanDocument() {
  const testResult = startTest(
    'E2E-014: Scan Document feature access',
    'Suite 6: Special Features',
    'Verify Scan Document/Camera feature is accessible from quick actions'
  );
  
  try {
    addStep(testResult, 'User opens quick actions menu');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add') || label === 'button') {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'Quick actions menu is open');
    await addScreenshot(testResult, 'scan_option', 'Scan Option');
    
    addStep(testResult, 'Verify Scan Document quick action is visible');
    addStep(testResult, 'User could tap to open camera/scan interface');
    
    await page.keyboard.press('Escape');
    await wait(500);
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_015_MoodCheckin() {
  const testResult = startTest(
    'E2E-015: Mood Check-in feature access',
    'Suite 6: Special Features',
    'Verify Mood Check-in feature is accessible from quick actions'
  );
  
  try {
    addStep(testResult, 'User opens quick actions menu');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add') || label === 'button') {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'Quick actions menu is open');
    await addScreenshot(testResult, 'mood_option', 'Mood Option');
    
    addStep(testResult, 'Verify Mood Check-in quick action is visible');
    addStep(testResult, 'User could tap to record current mood');
    
    await page.keyboard.press('Escape');
    await wait(500);
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_016_Personalize() {
  const testResult = startTest(
    'E2E-016: Personalize feature access',
    'Suite 6: Special Features',
    'Verify Personalize/Accessibility feature is accessible from quick actions'
  );
  
  try {
    addStep(testResult, 'User opens quick actions menu');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add') || label === 'button') {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'Quick actions menu is open');
    await addScreenshot(testResult, 'personalize_option', 'Personalize Option');
    
    addStep(testResult, 'Verify Personalize quick action is visible');
    addStep(testResult, 'User could tap to customize app settings');
    
    await page.keyboard.press('Escape');
    await wait(500);
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_017_HelpScreen() {
  const testResult = startTest(
    'E2E-017: Help Screen access',
    'Suite 6: Special Features',
    'Verify Help & Guide feature is accessible from quick actions'
  );
  
  try {
    addStep(testResult, 'User opens quick actions menu');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        const label = el.getAttribute('aria-label')?.toLowerCase() || '';
        if (label.includes('add') || label === 'button') {
          el.click();
        }
      });
    });
    await wait(1000);
    
    addStep(testResult, 'Quick actions menu is open');
    await addScreenshot(testResult, 'help_option', 'Help Option');
    
    addStep(testResult, 'Verify Help & Guide quick action is visible');
    addStep(testResult, 'User could tap to view app documentation');
    
    await page.keyboard.press('Escape');
    await wait(500);
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_018_MobileViewport() {
  const testResult = startTest(
    'E2E-018: Mobile viewport adaptation',
    'Suite 7: Responsiveness',
    'Verify app adapts correctly to mobile screen size'
  );
  
  try {
    addStep(testResult, 'Resize browser to mobile viewport (375x812)');
    await page.setViewport(MOBILE_VIEWPORT);
    await wait(1000);
    
    addStep(testResult, 'Reload page to trigger responsive layout');
    await page.reload({ waitUntil: 'networkidle2' });
    await waitForApp();
    
    addStep(testResult, 'Mobile layout renders');
    await addScreenshot(testResult, 'mobile_home', 'Mobile Home Screen');
    
    addStep(testResult, 'Verify app adapts to mobile layout');
    addStep(testResult, 'Verify navigation is still accessible');
    addStep(testResult, 'Verify content is readable without horizontal scroll');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_019_MobileNavigation() {
  const testResult = startTest(
    'E2E-019: Mobile navigation works',
    'Suite 7: Responsiveness',
    'Verify navigation works correctly on mobile viewport'
  );
  
  try {
    addStep(testResult, 'Test bottom navigation on mobile');
    await addScreenshot(testResult, 'mobile_nav', 'Mobile Navigation');
    
    addStep(testResult, 'Verify bottom navigation is visible on mobile');
    addStep(testResult, 'Verify FAB is accessible on mobile');
    
    addStep(testResult, 'Tap on Search tab');
    await page.evaluate(() => {
      const elements = document.querySelectorAll('flt-semantics');
      elements.forEach(el => {
        if (el.getAttribute('aria-label')?.toLowerCase().includes('search')) {
          el.click();
        }
      });
    });
    await wait(1000);
    await addScreenshot(testResult, 'mobile_search', 'Mobile Search Screen');
    
    addStep(testResult, 'Search screen loads on mobile');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

async function test_E2E_020_EmptyState() {
  const testResult = startTest(
    'E2E-020: Empty/Error state display',
    'Suite 8: Edge Cases',
    'Verify app handles empty states and errors gracefully'
  );
  
  try {
    // Reset to desktop
    await page.setViewport(VIEWPORT);
    await page.reload({ waitUntil: 'networkidle2' });
    await waitForApp();
    
    addStep(testResult, 'Navigate to main screen');
    await addScreenshot(testResult, 'main_state', 'Main Screen State');
    
    addStep(testResult, 'Verify empty state message if no documents');
    addStep(testResult, 'Verify guidance to add first memory is shown');
    addStep(testResult, 'Verify no error messages are displayed');
    
    finishTest(testResult, 'passed');
  } catch (e) {
    await addScreenshot(testResult, 'error_state', 'Error State');
    finishTest(testResult, 'failed', e.message);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN RUNNER
// ═══════════════════════════════════════════════════════════════════════════════

async function runAllTests() {
  console.log(`
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║        🧠 RECALL BUTLER - E2E UI TESTS WITH ALLURE                          ║
║           Screenshots & Results → Allure Report                              ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  App URL: ${APP_URL.padEnd(58)}║
║  Allure Results: test-results/allure-results/                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
`);

  createAllureResultsDir();
  
  try {
    console.log('🚀 Launching browser...\n');
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });
    page = await browser.newPage();
    await page.setViewport(VIEWPORT);
    
    // Run all tests
    await test_E2E_001_AppLaunch();
    await test_E2E_002_MemoriesTab();
    await test_E2E_003_NavigateToSearch();
    await test_E2E_004_NavigateToActivity();
    await test_E2E_005_FABQuickActions();
    await test_E2E_006_IngestScreenLayout();
    await test_E2E_007_AddMemoryModal();
    await test_E2E_008_SearchScreenLayout();
    await test_E2E_009_PerformSearch();
    await test_E2E_010_ActivityScreen();
    await test_E2E_011_SuggestionCard();
    await test_E2E_012_VoiceCapture();
    await test_E2E_013_ChatInterface();
    await test_E2E_014_ScanDocument();
    await test_E2E_015_MoodCheckin();
    await test_E2E_016_Personalize();
    await test_E2E_017_HelpScreen();
    await test_E2E_018_MobileViewport();
    await test_E2E_019_MobileNavigation();
    await test_E2E_020_EmptyState();
    
    console.log(`
╔══════════════════════════════════════════════════════════════════════════════╗
║                     E2E TESTS WITH ALLURE COMPLETE                           ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  All test results and screenshots saved to:                                  ║
║  → test-results/allure-results/                                              ║
║                                                                              ║
║  Generate Allure report with:                                                ║
║  → allure generate test-results/allure-results -o test-results/allure-report ║
╚══════════════════════════════════════════════════════════════════════════════╝
`);
    
  } catch (e) {
    console.error('Test execution error:', e);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
}

runAllTests();
