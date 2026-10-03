const { chromium } = require('playwright-core');
const [port, id, tag] = process.argv.slice(2);
(async () => {
  const b = await chromium.launch({ executablePath: process.env.HOME + '/.cache/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-linux64/chrome-headless-shell' });
  const p = await b.newPage({ viewport: { width: 1400, height: 1000 } });
  const reqs = [];
  p.on('request', r => { if (r.url().includes('/api/')) reqs.push(r.method() + ' ' + r.url().replace(/^https?:\/\/[^/]+/, '')); });
  let posted = null;
  await p.route('**/api/v1/artifacts', async (route) => {
    if (route.request().method() === 'POST') { posted = route.request().postData(); return route.fulfill({ status: 500, body: '{"error":"qa intercept"}' }); }
    return route.continue();
  });
  if (process.argv[5] === 'fail') await p.route('**/bundle-extensions', r => r.fulfill({ status: 500, body: '{"error":"qa"}' }));
  await p.goto(`http://127.0.0.1:${port}/`);
  await p.evaluate(() => localStorage.setItem('auroraboot_token', 'qa'));
  await p.goto(`http://127.0.0.1:${port}/artifacts/new?clone=${id}`);
  await p.getByText(/Clone:/).first().waitFor({ timeout: 15000 });
  await p.waitForTimeout(2000);
  const out = { tag, id };
  out.body = (await p.locator('main').innerText()).slice(0, 4000);
  out.hasMonitoring = out.body.includes('qa-monitoring');
  out.hasSiteConfig = out.body.includes('qa-site-config');
  await p.screenshot({ path: `/tmp/qa905/${tag}-${id}-landing.png`, fullPage: true });
  // go to Extensions step
  const btn = p.getByRole('button', { name: /Extensions/ }).first();
  await btn.click();
  await p.waitForTimeout(1000);
  await p.evaluate(() => document.querySelectorAll('details').forEach(d => d.open = true));
  await p.waitForTimeout(500);
  const ext = await p.locator('main').innerText();
  out.extStep = ext.slice(0, 5000);
  out.extHasVendor = ext.includes('/usr/local/lib/vendor');
  out.extHasConfext = ext.includes('/etc/vendor-site');
  out.extHasMonitoring = ext.includes('qa-monitoring');
  out.extHasSiteConfig = ext.includes('qa-site-config');
  await p.screenshot({ path: `/tmp/qa905/${tag}-${id}-extensions.png`, fullPage: true });
  if (process.argv[5] === 'fail') {}
  if (process.argv[5] === 'submit') {
    await p.getByRole('button', { name: /Review/ }).first().click();
    await p.waitForTimeout(800);
    await p.getByRole('button', { name: /Start build/ }).first().click();
    await p.waitForTimeout(2000);
    const j = posted ? JSON.parse(posted) : null;
    out.posted = j ? { keys: Object.keys(j), extensionHierarchies: j.extensionHierarchies ?? null, bundledExtensions: j.bundledExtensions ?? null } : null;
  }
  out.reqs = [...new Set(reqs)];
  console.log(JSON.stringify(out, null, 1));
  await b.close();
})().catch(e => { console.error(e); process.exit(1); });
