const { chromium } = require('playwright');

async function waitForFlutter(page, timeout = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    const found = await page.evaluate(() => !!document.querySelector('flt-glass-pane'));
    if (found) return true;
    await page.waitForTimeout(500);
  }
  return false;
}

async function enableA11y(page) {
  await page.evaluate(() => {
    const btn = document.querySelector('[aria-label="Enable accessibility"]');
    if (btn) btn.click();
  });
  await page.waitForTimeout(1500);
}

async function getVisibleText(page) {
  return page.evaluate(() => {
    const nodes = document.querySelectorAll('flt-semantics');
    return Array.from(nodes).map(n => n.getAttribute('aria-label') || n.textContent || '').join(' ');
  });
}

async function clickByText(page, text) {
  const clicked = await page.evaluate((searchText) => {
    const nodes = Array.from(document.querySelectorAll('flt-semantics'));
    // Find all nodes whose trimmed label/text IS exactly or closely the search text
    // Prefer the smallest bounding box (actual button, not parent container)
    let best = null;
    let bestArea = Infinity;
    for (const n of nodes) {
      const label = (n.getAttribute('aria-label') || n.textContent || '').trim();
      // Must be an exact or near-exact match — not just "contains"
      if (label.toLowerCase() === searchText.toLowerCase() ||
          label.toLowerCase().startsWith(searchText.toLowerCase()) && label.length < searchText.length + 5) {
        const rect = n.getBoundingClientRect();
        const area = rect.width * rect.height;
        if (area > 0 && area < bestArea) {
          best = { n, rect, label };
          bestArea = area;
        }
      }
    }
    if (best) {
      const cx = Math.round(best.rect.left + best.rect.width / 2);
      const cy = Math.round(best.rect.top + best.rect.height / 2);
      best.n.click();
      return `"${best.label}" area=${Math.round(bestArea)} at (${cx},${cy})`;
    }
    return null;
  }, text);
  console.log(`  CLICK "${text}":`, clicked || 'not found (using coord fallback)');
  return !!clicked;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();

  const errors = [];
  page.on('pageerror', e => errors.push(e.message));

  console.log('\n=== SpendLens E2E Test ===\n');

  let passed = 0; let failed = 0;
  const check = (label, condition) => {
    if (condition) { console.log(`[PASS] ${label}`); passed++; }
    else { console.log(`[FAIL] ${label}`); failed++; }
  };

  // 1: Splash
  await page.goto('http://localhost:7788', { waitUntil: 'load' });
  const ready = await waitForFlutter(page);
  await enableA11y(page);
  await page.screenshot({ path: 'e2e_1_splash.png' });
  check('Flutter canvas loaded', ready);

  // 2: Onboarding appears after splash
  await page.waitForTimeout(3000);
  await enableA11y(page);
  await page.screenshot({ path: 'e2e_2_onboarding.png' });
  const t2 = await getVisibleText(page);
  check('Onboarding text present', t2.length > 20);

  // 3: Navigate through 4 slides using Next
  for (let i = 1; i <= 4; i++) {
    const clicked = await clickByText(page, 'Next');
    if (!clicked) {
      await page.mouse.click(195, 808);
      console.log(`  [fallback] coord-click Next for slide ${i}`);
    }
    await page.waitForTimeout(1500);
  }
  await page.screenshot({ path: 'e2e_3_onboarding_last.png' });

  // 4: Auth screen after Get Started
  await clickByText(page, 'Get Started');
  await page.waitForTimeout(1500);
  await page.screenshot({ path: 'e2e_4_auth.png' });
  const t4 = await getVisibleText(page);
  console.log('  auth text:', t4.slice(0, 200));
  check('Auth: email field', t4.toLowerCase().includes('email') || t4.toLowerCase().includes('address'));
  check('Auth: Login button', t4.toLowerCase().includes('login'));
  check('Auth: Skip/no-login option', t4.toLowerCase().includes('continue') || t4.toLowerCase().includes('without'));
  check('Auth: No phone OTP UI', !t4.includes('+91') && !t4.toLowerCase().includes('send otp'));

  // 5: Skip to home
  await clickByText(page, 'Continue without login');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'e2e_5_home.png' });
  const t5 = await getVisibleText(page);
  console.log('  home text:', t5.slice(0, 200));
  check('Home: Dashboard visible', t5.toLowerCase().includes('dashboard') || t5.toLowerCase().includes('spent'));

  // 6: Nav tabs
  const tabs = [
    { label: 'Transactions', x: 117 },
    { label: 'Budget', x: 195 },
    { label: 'Insights', x: 273 },
    { label: 'Settings', x: 351 },
    { label: 'Home', x: 39 },
  ];
  for (const tab of tabs) {
    await page.mouse.click(tab.x, 820);
    await page.waitForTimeout(700);
    await page.screenshot({ path: `e2e_6_${tab.label.toLowerCase()}.png` });
    const tabTxt = await getVisibleText(page);
    check(`Nav: ${tab.label} renders`, tabTxt.length > 5);
  }

  console.log(`\n=== ${passed} passed, ${failed} failed ===`);
  console.log('[JS Errors]:', errors.length === 0 ? 'NONE' : errors.slice(0, 3).join('; '));

  await browser.close();
})();
