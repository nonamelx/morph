import { test, expect } from '@playwright/test';
import { readFile } from 'node:fs/promises';

async function studio(page) { await page.goto('/morph/'); await page.getByRole('button', { name: /Open Studio/ }).click(); }
async function menu(page) { await page.getByLabel('Profile actions').click(); }

test('release links open the correct page and support browser history', async ({ page }) => {
  await page.goto('/morph/#themes');
  await expect(page.getByRole('heading', { name: 'Find your palette.' })).toBeVisible();
  await page.getByRole('button', { name: 'Docs', exact: true }).focus();
  await expect(page.getByRole('button', { name: 'Docs', exact: true })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page).toHaveURL(/#docs$/);
  await expect(page.getByRole('heading', { name: 'Keep a palette' })).toBeVisible();
  await page.goBack();
  await expect(page.getByRole('heading', { name: 'Find your palette.' })).toBeVisible();
  await page.goto('/morph/#studio');
  await expect(page.getByRole('button', { name: 'Export Desktop' })).toBeVisible();
});

test('saved profiles survive reload and export valid JSON', async ({ page }) => {
  await page.goto('/morph/#studio');
  await page.getByLabel('Profile name').fill('Release test');
  await page.getByRole('button', { name: 'Save locally' }).click();
  await page.reload();
  await page.getByLabel('Saved profiles').selectOption({ label: 'Release test' });
  await expect(page.getByLabel('Profile name')).toHaveValue('Release test');
  await menu(page);
  const download = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Export JSON' }).click();
  const file = await download;
  expect(file.suggestedFilename()).toBe('Release test.json');
  await page.getByLabel('Import profile JSON').setInputFiles({
    name: file.suggestedFilename(),
    mimeType: 'application/json',
    buffer: await readFile(await file.path()),
  });
  await expect(page.getByRole('status')).toContainText('Profile imported');
  await page.getByLabel('Profile name').fill('');
  await menu(page);
  await page.getByRole('button', { name: 'Export JSON' }).click();
  await expect(page.getByRole('status')).toContainText('Enter a valid profile name');
});

test('profiles: menu, confirmation, rejected import and exports', async ({page}) => {
  await studio(page);
  await page.getByLabel('Profile name').fill('Test profile');
  await page.getByRole('button', {name:'Save locally'}).click();
  await expect(page.getByLabel('Saved profiles')).toContainText('Test profile');
  await menu(page); await page.getByRole('button',{name:'Duplicate current'}).click();
  await expect(page.getByLabel('Saved profiles')).toContainText('Test profile Copy');
  await menu(page); await page.getByRole('button',{name:'Delete selected'}).click();
  await expect(page.getByRole('dialog',{name:'Delete saved profile?'})).toBeVisible();
  await page.getByRole('button',{name:'Cancel'}).click();
  await expect(page.getByLabel('Saved profiles')).toContainText('Test profile Copy');
  await menu(page); await page.getByRole('button',{name:'Delete selected'}).click();
  await page.getByRole('button',{name:'Delete profile',exact:true}).click();
  await expect(page.getByLabel('Saved profiles')).not.toContainText('Test profile Copy');
  await page.getByLabel('Import profile JSON').setInputFiles({name:'bad.json',mimeType:'application/json',buffer:Buffer.from('{broken')});
  await expect(page.getByRole('status')).toContainText('valid JSON');
  await expect(page.getByLabel('Saved profiles')).toContainText('Test profile');
  const download=page.waitForEvent('download'); await page.getByRole('button',{name:'Export CLI'}).click(); expect((await download).suggestedFilename()).toMatch(/\.tmTheme$/);
  await expect(page.getByRole('button',{name:'Export Desktop'})).toBeVisible();
});

test('mobile view and comparison preserve editor state and history',async({page})=>{
  await page.setViewportSize({width:390,height:844}); await studio(page);
  await expect(page.getByRole('button',{name:'Preview',exact:true})).toHaveAttribute('aria-pressed','true');
  await page.getByRole('button',{name:'Edit',exact:true}).click();
  const accent=page.getByLabel('accent HEX'); const original=await accent.inputValue();
  await accent.fill('#123456'); await accent.blur();
  await page.getByRole('button',{name:'Preview',exact:true}).click();
  const preview=page.getByLabel('Illustrative Codex Desktop preview');
  await expect(preview).toHaveAttribute('style',/--accent: #123456/);
  await page.getByRole('button',{name:'Original',exact:true}).click();
  await expect(preview).toHaveAttribute('style',new RegExp(`--accent: ${original}`));
  await page.getByRole('button',{name:'CLI',exact:true}).click(); await expect(page.getByLabel('Illustrative Codex CLI preview')).toBeVisible();
  await page.getByRole('button',{name:'Edited',exact:true}).click();
  await page.getByRole('button',{name:'Edit',exact:true}).click(); await expect(accent).toHaveValue('#123456');
  await page.getByRole('button',{name:'Undo',exact:true}).click(); await expect(accent).toHaveValue(original);
  await page.getByRole('button',{name:'Redo',exact:true}).click(); await expect(accent).toHaveValue('#123456');
  await page.getByRole('button',{name:'Reset',exact:true}).click(); await expect(accent).toHaveValue(original);
  expect(await page.evaluate(()=>document.documentElement.scrollWidth <= innerWidth)).toBe(true);
});

test('CLI export uses the edited profile name in the filename and plist', async ({ page }) => {
  await studio(page);
  await page.getByLabel('Profile name').fill('Night & Day');

  const download = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Export CLI' }).click();
  const file = await download;

  expect(file.suggestedFilename()).toBe('night-day.tmTheme');
  expect(await readFile(await file.path(), 'utf8')).toContain('<key>name</key><string>Night &amp; Day</string>');
});

test('catalog arrows stay within the search and mode results', async ({ page }) => {
  await page.goto('/morph/#themes');
  const search = page.getByRole('textbox', { name: 'Search themes' });
  const next = page.getByRole('button', { name: 'Next theme' });
  const previous = page.getByRole('button', { name: 'Previous theme' });

  await search.fill('Ayu');
  await next.click();
  await expect(page.getByRole('heading', { name: 'Ayu Dark' })).toBeVisible();
  await next.click();
  await expect(page.getByRole('heading', { name: 'Ayu Light' })).toBeVisible();
  await next.click();
  await expect(page.getByRole('heading', { name: 'Ayu Dark' })).toBeVisible();
  await previous.click();
  await expect(page.getByRole('heading', { name: 'Ayu Light' })).toBeVisible();

  await page.getByRole('button', { name: 'dark', exact: true }).click();
  await previous.click();
  await expect(page.getByRole('heading', { name: 'Ayu Dark' })).toBeVisible();

  await search.fill('no matching theme');
  await expect(next).toBeDisabled();
  await expect(previous).toBeDisabled();
});
