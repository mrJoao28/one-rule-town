import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const apiKey = process.env.ROBLOX_ASSET_API_KEY;
const placeId = process.env.ROBLOX_PLACE_ID;
const userId = "11865929955";
assert(apiKey && placeId, "ROBLOX_ASSET_API_KEY and ROBLOX_PLACE_ID are required");

const base = "https://apis.roblox.com/assets/v1";
const headers = { "x-api-key": apiKey };

async function call(path, options = {}) {
  const response = await fetch(`${base}/${path}`, { ...options, headers });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    throw new Error(`Roblox Assets API ${options.method || "GET"} ${path}: HTTP ${response.status} ${JSON.stringify(body)}`);
  }
  return body;
}

async function operation(result) {
  if (!result.path) return result;
  assert(/^operations\/[A-Za-z0-9_-]+$/.test(result.path), "Unexpected operation path");
  for (let attempt = 0; attempt < 30; attempt++) {
    const current = await call(result.path);
    if (current.done) {
      if (current.error) throw new Error(`Asset operation failed: ${JSON.stringify(current.error)}`);
      return current.response || current;
    }
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  throw new Error(`Asset operation timed out: ${result.path}`);
}

function form(request, file, filename) {
  const data = new FormData();
  data.append("request", new Blob([JSON.stringify(request)], { type: "application/json" }));
  if (file) data.append("fileContent", new Blob([file], { type: "image/jpeg" }), filename);
  return data;
}

async function upload(filename, title) {
  const file = await readFile(new URL(`../assets/marketing/${filename}`, import.meta.url));
  const result = await operation(await call("assets", {
    method: "POST",
    body: form({
      assetType: "Image",
      displayName: title,
      description: "Original One Rule Town experience artwork",
      creationContext: { creator: { userId }, assetPrivacy: "OpenUse" },
    }, file, filename),
  }));
  assert(result.assetId, `No assetId returned for ${filename}`);
  console.log(`${title} uploaded as asset ${result.assetId}; moderation: ${result.moderationResult?.moderationState || "pending"}`);
  return result.assetId;
}

async function update(mask, request) {
  return operation(await call(`assets/${placeId}?updateMask=${mask}`, {
    method: "PATCH",
    body: form({ assetId: placeId, ...request }),
  }));
}

// Check read access and preserve any existing previews before creating assets.
const current = await call(`assets/${placeId}?readMask=icon,previews`);
const iconId = await upload("icon.jpg", "One Rule Town Icon");
const thumbnailId = await upload("thumbnail.jpg", "One Rule Town Cover");
await update("icon", { icon: `assets/${iconId}` });
const altText = "One Rule Town players escaping the Mayor and rising lava";
const previews = (current.previews || []).filter(preview => preview.altText !== altText);
previews.unshift({ asset: `assets/${thumbnailId}`, altText });
await update("previews", { previews });

const verified = await call(`assets/${placeId}?readMask=icon,previews`);
assert.equal(verified.icon, `assets/${iconId}`, "Icon did not persist");
assert(verified.previews?.some(preview => preview.asset === `assets/${thumbnailId}`), "Cover did not persist");
console.log("One Rule Town icon and cover saved to the Roblox place. Images appear after moderation.");
