// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * 🧠 RECALL BUTLER - E2E UI TESTS WITH PLAYWRIGHT
 * Proper browser interactions with distinct screenshots
 */

const APP_URL = '/app/';

// Simple wait for Flutter - just wait for network idle and some extra time
async function waitForFlutter(page, extraWait = 3000) {
  await page.waitForLoadState('domcontentloaded');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(extraWait);
}

// Get nav positions based on viewport
function getNavPositions(viewport) {
  return {
    memories: { x: viewport.width * 0.17, y: viewport.height - 35 },
    search: { x: viewport.width * 0.5, y: viewport.height - 35 },
    activity: { x: viewport.width * 0.83, y: viewport.height - 35 },
    fab: { x: viewport.width - 56, y: viewport.height - 90 },
  };
}

test.describe('Suite 1: App Launch', () => {
  test('E2E-001: App loads successfully', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-001_app_loaded.png' });
    
    // Verify page loaded
    expect(await page.title()).toBeTruthy();
  });

  test('E2E-002: App displays content', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    // Take full page screenshot
    await page.screenshot({ 
      path: '../test-results/e2e-screenshots/E2E-002_full_page.png',
      fullPage: true 
    });
  });
});

test.describe('Suite 2: Navigation', () => {
  test('E2E-003: Click on Search tab', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-003_01_home.png' });
    
    await page.mouse.click(nav.search.x, nav.search.y);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-003_02_search.png' });
  });

  test('E2E-004: Click on Activity tab', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.activity.x, nav.activity.y);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-004_activity.png' });
  });

  test('E2E-005: Navigate through all tabs', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    // Home
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-005_01_home.png' });
    
    // Search
    await page.mouse.click(nav.search.x, nav.search.y);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-005_02_search.png' });
    
    // Activity
    await page.mouse.click(nav.activity.x, nav.activity.y);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-005_03_activity.png' });
    
    // Back to Memories
    await page.mouse.click(nav.memories.x, nav.memories.y);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-005_04_back_home.png' });
  });
});

test.describe('Suite 3: FAB Menu', () => {
  test('E2E-006: Open FAB menu', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-006_01_before_fab.png' });
    
    await page.mouse.click(nav.fab.x, nav.fab.y);
    await page.waitForTimeout(800);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-006_02_fab_open.png' });
  });

  test('E2E-007: Close FAB by clicking outside', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    // Open FAB
    await page.mouse.click(nav.fab.x, nav.fab.y);
    await page.waitForTimeout(800);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-007_01_fab_open.png' });
    
    // Click outside
    await page.mouse.click(100, 100);
    await page.waitForTimeout(500);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-007_02_fab_closed.png' });
  });

  test('E2E-008: Click FAB option 1 (top)', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.fab.x, nav.fab.y);
    await page.waitForTimeout(800);
    
    // Click first option above FAB
    await page.mouse.click(nav.fab.x, nav.fab.y - 70);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-008_fab_option1.png' });
  });

  test('E2E-009: Click FAB option 2', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.fab.x, nav.fab.y);
    await page.waitForTimeout(800);
    
    await page.mouse.click(nav.fab.x, nav.fab.y - 140);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-009_fab_option2.png' });
  });

  test('E2E-010: Click FAB option 3', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.fab.x, nav.fab.y);
    await page.waitForTimeout(800);
    
    await page.mouse.click(nav.fab.x, nav.fab.y - 210);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-010_fab_option3.png' });
  });
});

test.describe('Suite 4: Search', () => {
  test('E2E-011: View search screen', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.search.x, nav.search.y);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-011_search_screen.png' });
  });

  test('E2E-012: Click search field and type', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    // Go to search
    await page.mouse.click(nav.search.x, nav.search.y);
    await page.waitForTimeout(1500);
    
    // Click on search field area
    await page.mouse.click(viewport.width / 2, 100);
    await page.waitForTimeout(500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-012_01_search_focused.png' });
    
    // Type query
    await page.keyboard.type('invoice', { delay: 80 });
    await page.waitForTimeout(500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-012_02_typing.png' });
  });

  test('E2E-013: Execute search', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.search.x, nav.search.y);
    await page.waitForTimeout(1500);
    
    await page.mouse.click(viewport.width / 2, 100);
    await page.waitForTimeout(300);
    await page.keyboard.type('payment due', { delay: 50 });
    await page.keyboard.press('Enter');
    await page.waitForTimeout(3000);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-013_search_results.png' });
  });
});

test.describe('Suite 5: Activity', () => {
  test('E2E-014: View activity screen', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.activity.x, nav.activity.y);
    await page.waitForTimeout(2000);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-014_activity.png' });
  });

  test('E2E-015: Scroll activity screen', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.activity.x, nav.activity.y);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-015_01_activity_top.png' });
    
    // Scroll down
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(800);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-015_02_activity_scrolled.png' });
  });
});

test.describe('Suite 6: Ingest', () => {
  test('E2E-016: View ingest screen', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-016_ingest_screen.png' });
  });

  test('E2E-017: Click quick action buttons', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    
    // Click Upload area
    await page.mouse.click(viewport.width * 0.25, 250);
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-017_01_upload.png' });
    
    // Press Escape to close any modal
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);
    
    // Click Paste area
    await page.mouse.click(viewport.width * 0.5, 250);
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-017_02_paste.png' });
  });

  test('E2E-018: Scroll to recent memories', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-018_01_top.png' });
    
    await page.mouse.wheel(0, 400);
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-018_02_scrolled.png' });
  });
});

test.describe('Suite 7: Document Interaction', () => {
  test('E2E-019: Click on document card', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    
    // Scroll to documents
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(800);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-019_01_documents.png' });
    
    // Click on a document
    await page.mouse.click(viewport.width / 2, 400);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-019_02_doc_detail.png' });
  });

  test('E2E-020: Navigate back from detail', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    
    await page.mouse.wheel(0, 300);
    await page.waitForTimeout(500);
    await page.mouse.click(viewport.width / 2, 400);
    await page.waitForTimeout(1500);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-020_01_on_detail.png' });
    
    // Back button
    await page.mouse.click(50, 50);
    await page.waitForTimeout(1000);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-020_02_back.png' });
  });
});

test.describe('Suite 8: Mobile', () => {
  test('E2E-021: Mobile viewport home', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-021_mobile_home.png' });
  });

  test('E2E-022: Mobile navigation', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-022_01_mobile_home.png' });
    
    await page.mouse.click(nav.search.x, nav.search.y);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-022_02_mobile_search.png' });
    
    await page.mouse.click(nav.activity.x, nav.activity.y);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-022_03_mobile_activity.png' });
  });

  test('E2E-023: Mobile FAB', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    await page.mouse.click(nav.fab.x, nav.fab.y);
    await page.waitForTimeout(800);
    
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-023_mobile_fab.png' });
  });
});

test.describe('Suite 9: User Journey', () => {
  test('E2E-024: Complete user flow', async ({ page }) => {
    await page.goto(APP_URL);
    await waitForFlutter(page);
    
    const viewport = page.viewportSize();
    const nav = getNavPositions(viewport);
    
    // Step 1: Home
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-024_01_start.png' });
    
    // Step 2: Search
    await page.mouse.click(nav.search.x, nav.search.y);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-024_02_search.png' });
    
    // Step 3: Type and search
    await page.mouse.click(viewport.width / 2, 100);
    await page.waitForTimeout(300);
    await page.keyboard.type('test', { delay: 50 });
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-024_03_results.png' });
    
    // Step 4: Activity
    await page.mouse.click(nav.activity.x, nav.activity.y);
    await page.waitForTimeout(1500);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-024_04_activity.png' });
    
    // Step 5: FAB
    await page.mouse.click(nav.fab.x, nav.fab.y);
    await page.waitForTimeout(800);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-024_05_fab.png' });
    
    // Step 6: Back home
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    await page.mouse.click(nav.memories.x, nav.memories.y);
    await page.waitForTimeout(1000);
    await page.screenshot({ path: '../test-results/e2e-screenshots/E2E-024_06_end.png' });
  });
});
