const { buildPlaceScript, clientBannerScript, checkScript } = require("./generator.js");
const fs = require("fs");
const path = require("path");

const genres = ["obby", "tycoon", "simulator", "horror", "race", "arena"];
const out = path.join(__dirname, "samples");
fs.mkdirSync(out, { recursive: true });
let failed = 0;
for (const genre of genres) {
  const src = buildPlaceScript("Test " + genre, genre, "self-test prompt for " + genre);
  const errors = checkScript(src, genre);
  fs.writeFileSync(path.join(out, genre + ".server.lua"), src);
  if (errors.length) {
    failed += 1;
    console.log("FAIL", genre, errors.join("; "));
  } else {
    console.log("PASS", genre, src.split("\n").length, "lines");
  }
}
const client = clientBannerScript();
fs.writeFileSync(path.join(out, "StatusBanner.client.lua"), client);
if (!client.includes("OnClientEvent") || !client.includes("ScreenGui")) {
  failed += 1;
  console.log("FAIL client banner");
} else {
  console.log("PASS client banner", client.split("\n").length, "lines");
}
if (failed) {
  console.log("SELF-TEST FAILED", failed);
  process.exit(1);
}
console.log("SELF-TEST OK", genres.length, "server scripts + 1 client banner");
