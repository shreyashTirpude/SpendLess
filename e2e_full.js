const { chromium } = require('playwright');
const path = require('path');

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
  await page.waitForTimeout(1200);
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
    let best = null; let bestArea = Infinity;
    for (const n of nodes) {
      const label = (n.getAttribute('aria-label') || n.textContent || '').trim();
      if (label.toLowerCase() === searchText.toLowerCase() ||
         (label.toLowerCase().startsWith(searchText.toLowerCase()) && label.length < searchText.length + 5)) {
        const rect = n.getBoundingClientRect();
        const area = rect.width * rect.height;
        if (area > 0 && area < bestArea) { best = { n, rect }; bestArea = area; }
      }
    }
    if (best) { best.n.click(); return true; }
    return false;
  }, text);
  return clicked;
}

async function shot(page, name, label) {
  await page.screenshot({ path: `e2e_full_${name}.png`, fullPage: false });
  console.log(`  📸 ${label}`);
}

(async () => {
  const browser = await chromium.launch({ headless: false, slowMo: 200 });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();

  const errors = [];
  page.on('pageerror', e => errors.push(e.message));

  let passed = 0; let failed = 0;
  const check = (label, cond) => {
    if (cond) { console.log(`  ✅ ${label}`); passed++; }
    else { console.log(`  ❌ ${label}`); failed++; }
    return cond;
  };

  console.log('\n╔════════════════════════════════╗');
  console.log('║   SpendLens Full E2E Test      ║');
  console.log('╚════════════════════════════════╝\n');

  // ── SCREEN 1: Splash ─────────────────────────────────────────
  console.log('【1】 Splash Screen');
  await page.goto('http://localhost:7788', { waitUntil: 'load' });
  const ready = await waitForFlutter(page);
  await enableA11y(page);
  await shot(page, '01_splash', 'Splash screen');
  check('Flutter canvas loaded', ready);

  // ── SCREEN 2: Onboarding slide 1 ─────────────────────────────
  console.log('\n【2】 Onboarding');
  await page.waitForTimeout(2800);
  await enableA11y(page);
  const t_ob1 = await getVisibleText(page);
  await shot(page, '02_onboarding_1', 'Onboarding slide 1');
  check('Slide 1 text present', t_ob1.length > 10);

  // Slide 2
  await clickByText(page, 'Next'); await page.waitForTimeout(1200);
  await shot(page, '03_onboarding_2', 'Onboarding slide 2');

  // Slide 3
  await clickByText(page, 'Next'); await page.waitForTimeout(1200);
  await shot(page, '04_onboarding_3', 'Onboarding slide 3');

  // Slide 4 (Last)
  await clickByText(page, 'Next'); await page.waitForTimeout(1200);
  await shot(page, '05_onboarding_4', 'Onboarding slide 4 (last)');
  const t_ob4 = await getVisibleText(page);
  check('4 slides navigated', t_ob4.length > 5);

  // ── SCREEN 3: Auth ───────────────────────────────────────────
  console.log('\n【3】 Auth Screen');
  await page.mouse.click(195, 808); // Get Started (fallback coord)
  await page.waitForTimeout(1200);
  await shot(page, '06_auth_login', 'Auth — Login view');
  const t_auth = await getVisibleText(page);
  check('Email field visible', t_auth.toLowerCase().includes('email'));
  check('Login button visible', t_auth.toLowerCase().includes('login'));
  check('Skip button visible', t_auth.toLowerCase().includes('continue without'));
  check('No phone OTP', !t_auth.includes('+91') && !t_auth.toLowerCase().includes('send otp'));

  // Test toggle to sign-up
  await clickByText(page, "Don't have an account? Sign up");
  await page.waitForTimeout(800);
  await shot(page, '07_auth_signup', 'Auth — Sign Up view');
  const t_signup = await getVisibleText(page);
  check('Name field on sign-up', t_signup.toLowerCase().includes('name') || t_signup.toLowerCase().includes('full'));
  check('Create Account button', t_signup.toLowerCase().includes('create'));

  // Test empty submit validation
  await clickByText(page, 'Create Account');
  await page.waitForTimeout(600);
  await shot(page, '08_auth_validation', 'Auth — validation snackbar');

  // ── SCREEN 4: Home (skip login) ──────────────────────────────
  console.log('\n【4】 Home Dashboard');
  await clickByText(page, 'Continue without login');
  await page.waitForTimeout(1500);
  await shot(page, '09_home', 'Home Dashboard');
  const t_home = await getVisibleText(page);
  check('Dashboard title', t_home.toLowerCase().includes('dashboard'));
  check('SPENT card', t_home.toLowerCase().includes('spent'));
  check('INCOME card', t_home.toLowerCase().includes('income'));
  check('Recent Transactions section', t_home.toLowerCase().includes('recent'));

  // ── SCREEN 5: Transactions tab ───────────────────────────────
  console.log('\n【5】 Transactions Tab');
  await page.mouse.click(117, 820);
  await page.waitForTimeout(700);
  await shot(page, '10_transactions', 'Transactions screen');
  const t_tx = await getVisibleText(page);
  check('Transactions screen loads', t_tx.toLowerCase().includes('transaction'));

  // ── SCREEN 6: Budget tab ─────────────────────────────────────
  console.log('\n【6】 Budget Tab');
  await page.mouse.click(195, 820);
  await page.waitForTimeout(700);
  await shot(page, '11_budget', 'Budget screen');
  const t_bgt = await getVisibleText(page);
  check('Budget screen loads', t_bgt.toLowerCase().includes('budget'));

  // ── SCREEN 7: Insights tab ───────────────────────────────────
  console.log('\n【7】 Insights Tab');
  await page.mouse.click(273, 820);
  await page.waitForTimeout(700);
  await shot(page, '12_insights', 'Insights screen');
  const t_ins = await getVisibleText(page);
  check('Insights screen loads', t_ins.toLowerCase().includes('insight') || t_ins.toLowerCase().includes('spent'));

  // ── SCREEN 8: Settings tab ───────────────────────────────────
  console.log('\n【8】 Settings Tab');
  await page.mouse.click(351, 820);
  await page.waitForTimeout(700);
  await shot(page, '13_settings', 'Settings screen');
  const t_set = await getVisibleText(page);
  check('Settings screen loads', t_set.toLowerCase().includes('setting'));
  check('Biometric Lock toggle', t_set.toLowerCase().includes('biometric'));
  check('Notification toggles', t_set.toLowerCase().includes('notification') || t_set.toLowerCase().includes('alert'));

  // ── SCREEN 9: Back to Home ────────────────────────────────────
  console.log('\n【9】 Return to Home');
  await page.mouse.click(39, 820);
  await page.waitForTimeout(700);
  await shot(page, '14_home_final', 'Home — final state');

  // ── Summary ──────────────────────────────────────────────────
  console.log(`\n╔════════════════════════════════╗`);
  console.log(`║  Results: ${passed}/${passed+failed} tests passed  `.padEnd(33) + '║');
  console.log(`╚════════════════════════════════╝`);
  if (errors.length > 0) {
    console.log('JS Errors:', errors.slice(0, 3));
  } else {
    console.log('✅ Zero JavaScript errors');
  }

  await page.waitForTimeout(3000); // keep browser open briefly so user can see
  await browser.close();
})();
