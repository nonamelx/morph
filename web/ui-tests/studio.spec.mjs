import { test, expect } from '@playwright/test';

async function studio(page) { await page.goto('/morph/'); await page.getByRole('button', { name: /Open Studio/ }).click(); }
async function menu(page) { await page.getByLabel('Profile actions').click(); }

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
