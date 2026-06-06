const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  // Launch browser — use existing logged-in session
  const browser = await chromium.launch({ headless: false, slowMo: 100 });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('🔍 Checking GitHub login status...');
  await page.goto('https://github.com');
  await page.waitForLoadState('networkidle');

  // Check if already logged in
  const isLoggedIn = await page.locator('[aria-label="View profile and more"]').isVisible()
    .catch(() => false);

  if (!isLoggedIn) {
    console.log('⚠️  Not logged in. Please log in manually in the browser window.');
    await page.goto('https://github.com/login');
    // Wait for user to log in manually (max 60 seconds)
    await page.waitForURL('https://github.com', { timeout: 60000 });
    console.log('✅ Logged in successfully!');
  } else {
    console.log('✅ Already logged in to GitHub!');
  }

  // Get username from GitHub
  const username = await page.evaluate(() => {
    const metaTag = document.querySelector('meta[name="user-login"]');
    return metaTag ? metaTag.getAttribute('content') : null;
  });
  console.log(`👤 GitHub username: ${username}`);

  // Navigate to new repo creation page
  console.log('📦 Creating new repository...');
  await page.goto('https://github.com/new');
  await page.waitForLoadState('networkidle');

  // Fill repo name
  await page.fill('#repository_name', 'spendlens');
  await page.waitForTimeout(500);

  // Fill description
  await page.fill('#repository_description',
    'Auto SMS-based expense tracker for Android. Zero manual entry. Flutter + Supabase.');

  // Set to Private
  await page.click('#repository_visibility_private');

  // Add README
  await page.check('#repository_initialize');

  // Add .gitignore — select Dart
  await page.click('.js-gitignore-field');
  await page.waitForTimeout(300);
  await page.fill('.js-gitignore-field input', 'Dart');
  await page.waitForTimeout(500);
  await page.click('.js-gitignore-field .autocomplete-item:first-child')
    .catch(async () => {
      await page.keyboard.press('Enter');
    });

  // Choose license — MIT
  await page.click('.js-license-field');
  await page.waitForTimeout(300);
  await page.fill('.js-license-field input', 'MIT');
  await page.waitForTimeout(500);
  await page.click('.js-license-field .autocomplete-item:first-child')
    .catch(async () => {
      await page.keyboard.press('Enter');
    });

  // Submit
  await page.click('[data-target="new-repository.createButton"], button[type="submit"]');
  await page.waitForURL(/github\.com\/.+\/spendlens/, { timeout: 15000 });

  const repoUrl = page.url();
  console.log(`\n🎉 Repository created successfully!`);
  console.log(`🔗 URL: ${repoUrl}`);
  console.log(`📋 Clone URL: https://github.com/${username}/spendlens.git`);

  // Save config
  const scriptsDir = path.join(__dirname);
  if (!fs.existsSync(scriptsDir)) {
    fs.mkdirSync(scriptsDir, { recursive: true });
  }

  fs.writeFileSync(path.join(scriptsDir, '.github_config.json'), JSON.stringify({
    username,
    repoUrl,
    cloneUrl: `https://github.com/${username}/spendlens.git`,
  }, null, 2));

  console.log('\n✅ GitHub setup complete!');
  await browser.close();
})().catch(err => {
  console.error('❌ Error:', err);
  process.exit(1);
});
