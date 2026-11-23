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
  await expect(page.getByRole('link', { name: /Windows CLI theme tutorial/ })).toHaveAttribute('href', 'https://github.com/nonamelx/morph/blob/main/docs/windows-cli-theme.md');
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

test('saving edits updates the selected profile while duplicate creates a separate copy', async ({ page }) => {
  await studio(page);
  const profileName = page.getByRole('textbox', { name: 'Profile name' });
  const savedProfiles = page.getByLabel('Saved profiles');
  const save = page.getByRole('button', { name: 'Save locally' });

  await profileName.fill('Daily work');
  await save.click();
  const profileId = await savedProfiles.inputValue();
  await profileName.fill('Daily work edited');
  const accent = page.getByRole('textbox', { name: 'accent HEX', exact: true });
  await accent.fill('#89b4fa');
  await accent.blur();
  await save.click();

  await expect(savedProfiles).toHaveValue(profileId);
  await expect(savedProfiles.getByRole('option')).toHaveCount(2);
  await page.reload();
  await savedProfiles.selectOption(profileId);
  await expect(profileName).toHaveValue('Daily work edited');
  await expect(accent).toHaveValue('#89b4fa');

  await menu(page);
  await page.getByRole('button', { name: 'Duplicate current' }).click();
  await expect(savedProfiles.getByRole('option')).toHaveCount(3);
  await expect(savedProfiles).toContainText('Daily work edited Copy');
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

test('navigation moves keyboard focus to the new page heading', async ({ page }) => {
  await page.goto('/morph/#themes');
  const button = page.getByRole('button', { name: 'Open in Studio' });
  await button.focus();
  await page.keyboard.press('Enter');
  await expect(page.getByRole('heading', { level: 1 })).toBeFocused();

  await page.goBack();
  await expect(page.getByRole('heading', { name: 'Find your palette.' })).toBeFocused();
});

test('command search returns focus to the destination after selecting a theme', async ({ page }) => {
  await page.goto('/morph/#studio');
  await page.getByRole('button', { name: 'Search themes' }).click();
  const dialog = page.getByRole('dialog', { name: 'Search themes' });
  await dialog.getByRole('textbox', { name: 'Search themes' }).fill('Ayu Dark');
  await dialog.getByRole('button', { name: /Ayu Dark/ }).click();
  await expect(page.getByRole('heading', { name: 'Find your palette.' })).toBeFocused();
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

test('command search reveals its selected theme after gallery filtering', async ({ page }) => {
  await page.goto('/morph/#themes');
  const gallerySearch = page.getByRole('textbox', { name: 'Search themes' });
  await gallerySearch.fill('Ayu');
  await page.getByRole('button', { name: 'light', exact: true }).click();

  await page.getByRole('button', { name: 'Search themes' }).click();
  const dialog = page.getByRole('dialog', { name: 'Search themes' });
  await dialog.getByRole('textbox', { name: 'Search themes' }).fill('Nord');
  await dialog.getByRole('button', { name: 'Nord dark' }).click();

  await expect(gallerySearch).toHaveValue('');
  await expect(page.getByRole('button', { name: 'all', exact: true })).toHaveAttribute('aria-pressed', 'true');
  await expect(page.getByRole('heading', { name: 'Nord', exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Nord dark' })).toHaveClass(/current/);
});

test('mobile navigation closes with Escape and restores focus', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/morph/');
  const toggle = page.getByRole('button', { name: 'Toggle navigation' });
  const nav = page.getByRole('navigation', { name: 'Main navigation' });

  await toggle.focus();
  await page.keyboard.press('Enter');
  await expect(toggle).toHaveAttribute('aria-expanded', 'true');
  await expect(nav).toBeVisible();
  await page.getByRole('button', { name: 'Themes', exact: true }).focus();
  await page.keyboard.press('Escape');
  await expect(nav).toBeHidden();
  await expect(toggle).toHaveAttribute('aria-expanded', 'false');
  await expect(toggle).toBeFocused();
});

test('gallery previews and copies the base theme while preserving Studio edits', async ({ page, context }) => {
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  await page.goto('/morph/#studio');
  const accent = page.getByLabel('accent HEX');
  const originalAccent = await accent.inputValue();
  await accent.fill('#123456');
  await accent.blur();

  await page.getByRole('button', { name: 'Themes', exact: true }).click();
  const preview = page.getByLabel('Illustrative Codex Desktop preview');
  await expect(preview).toHaveAttribute('style', new RegExp(`--accent: ${originalAccent}`));
  await page.getByText('View import string').click();
  const galleryImport = await page.getByLabel('Import string').inputValue();
  expect(JSON.parse(galleryImport.slice('codex-theme-v1:'.length)).theme.accent).toBe(originalAccent);
  await page.getByRole('button', { name: 'Copy import' }).click();
  expect(await page.evaluate(() => navigator.clipboard.readText())).toBe(galleryImport);

  await page.getByRole('button', { name: 'Customize in Studio →' }).click();
  await expect(accent).toHaveValue('#123456');
});
