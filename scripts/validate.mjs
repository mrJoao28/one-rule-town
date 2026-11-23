import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const read = (relativePath) => fs.readFileSync(path.join(root, relativePath), "utf8");

const project = JSON.parse(read("default.project.json"));
assert.equal(project.name, "OneRuleTown");
assert.equal(project.tree.ReplicatedStorage.Shared.$path, "src/shared");
assert.equal(project.tree.ServerScriptService.Server.$path, "src/server");
assert.equal(project.tree.StarterPlayer.StarterPlayerScripts.Client.$path, "src/client");

const rulesDirectory = path.join(root, "src/server/Rules");
const ruleFiles = fs.readdirSync(rulesDirectory)
	.filter((file) => file.endsWith(".luau") && file !== "RuleUtils.luau")
	.sort();

assert.equal(ruleFiles.length, 11, "The game must ship with eleven rules");

const catalog = read("src/shared/RuleCatalog.luau");
const ruleIds = [];
for (const file of ruleFiles) {
	const source = read(`src/server/Rules/${file}`);
	const match = source.match(/Id\s*=\s*"([A-Za-z0-9]+)"/);
	assert.ok(match, `${file} must declare a rule Id`);
	const id = match[1];
	assert.ok(!ruleIds.includes(id), `Duplicate rule Id: ${id}`);
	assert.match(catalog, new RegExp(`\\b${id}\\s*=`), `${id} must exist in RuleCatalog`);
	ruleIds.push(id);
}

for (const requiredFile of [
	"src/server/Bootstrap.server.luau",
	"src/client/Bootstrap.client.luau",
	"src/server/Services/RoundService.luau",
	"src/server/Services/DataService.luau",
	"src/server/Services/MonetizationService.luau",
	"src/server/Services/MapService.luau",
]) {
	assert.ok(fs.existsSync(path.join(root, requiredFile)), `Missing ${requiredFile}`);
}

console.log(`Validated One Rule Town: ${ruleIds.length} rules and complete Rojo structure.`);

