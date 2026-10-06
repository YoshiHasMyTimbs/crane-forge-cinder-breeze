function scriptsFor(title, genre, prompt) {
  const api = typeof buildPlaceScript === "function"
    ? { buildPlaceScript, clientBannerScript }
    : require("./generator.js");
  return {
    server: api.buildPlaceScript(title, genre, prompt),
    client: api.clientBannerScript(),
  };
}

function esc(text) {
  return String(text).replace(/&/g, "&").replace(/</g, "<").replace(/>/g, ">");
}
function cdata(text) {
  return String(text).replace(/\]\]>/g, "]]]]><![CDATA[>");
}
let ref = 1;
function id() {
  ref += 1;
  return "RBX" + ref.toString(16).padStart(8, "0");
}
function color(r, g, b) {
  return `<Color3 name="Color"><R>${r / 255}</R><G>${g / 255}</G><B>${b / 255}</B></Color3>`;
}
function vec(x, y, z) {
  return `<Vector3 name="Size"><X>${x}</X><Y>${y}</Y><Z>${z}</Z></Vector3>`;
}
function cf(x, y, z) {
  return `<CoordinateFrame name="CFrame"><X>${x}</X><Y>${y}</Y><Z>${z}</Z><R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>`;
}
function partXml(name, x, y, z, sx, sy, sz, r, g, b) {
  return `<Item class="Part" referent="${id()}">
    <Properties>
      <string name="Name">${esc(name)}</string>
      <bool name="Anchored">true</bool>
      ${color(r, g, b)}
      ${vec(sx, sy, sz)}
      ${cf(x, y, z)}
      <token name="Material">256</token>
    </Properties>
  </Item>`;
}

function mapParts(genre) {
  const parts = [partXml("SpawnPad", 0, 1, 0, 24, 1, 24, 36, 40, 52)];
  if (genre === "obby") {
    for (let i = 1; i <= 12; i += 1) {
      parts.push(partXml("Jump" + i, i * 14, 2 + (i % 3) * 4, 0, 10, 1, 10, 255, 70 + i * 8, 40));
      if (i % 3 === 0) parts.push(partXml("Checkpoint" + i, i * 14, 4 + (i % 3) * 4, 0, 6, 1, 6, 80, 220, 140));
    }
    parts.push(partXml("WinPad", 13 * 14, 8, 0, 12, 1, 12, 255, 208, 60));
  } else if (genre === "tycoon") {
    parts.push(partXml("Plot", 0, 1, 0, 40, 1, 40, 48, 42, 36));
    parts.push(partXml("Dropper", -10, 8, 0, 6, 4, 6, 180, 90, 40));
    parts.push(partXml("Collector", 12, 2, 0, 8, 1, 8, 80, 200, 120));
    parts.push(partXml("Upgrade", 0, 2, 12, 6, 1, 6, 255, 180, 40));
  } else if (genre === "simulator") {
    parts.push(partXml("MintPad", 0, 2, 0, 16, 1, 16, 40, 180, 120));
    parts.push(partXml("Rebirth", 0, 2, 22, 10, 1, 10, 160, 90, 255));
  } else if (genre === "horror") {
    parts.push(partXml("Lobby", 0, 1, 0, 60, 1, 60, 18, 18, 22));
    for (let i = 1; i <= 8; i += 1) {
      parts.push(partXml("Cover" + i, Math.cos(i) * 18, 5, Math.sin(i) * 18, 6, 8, 2, 32, 32, 38));
    }
  } else if (genre === "race") {
    for (let i = 0; i <= 7; i += 1) {
      const angle = (i / 8) * Math.PI * 2;
      const gold = i === 0;
      parts.push(partXml("Gate" + i, Math.cos(angle) * 40, 2, Math.sin(angle) * 40, 10, 1, 6, gold ? 255 : 70, gold ? 210 : 130, gold ? 60 : 255));
    }
  } else {
    parts.push(partXml("Arena", 0, 1, 0, 70, 1, 70, 50, 36, 70));
    for (let i = 1; i <= 6; i += 1) {
      parts.push(partXml("Pillar" + i, Math.cos(i) * 20, 6, Math.sin(i) * 20, 4, 10, 4, 90, 70, 130));
    }
  }
  return parts.join("\n");
}

function buildRbxlx(title, genre, prompt) {
  ref = 1;
  const packed = scriptsFor(title, genre, prompt);
  const server = packed.server;
  const client = packed.client;
  return `<?xml version="1.0" encoding="utf-8"?>
<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
  <Item class="Workspace" referent="${id()}">
    <Properties><string name="Name">Workspace</string></Properties>
    <Item class="Folder" referent="${id()}">
      <Properties><string name="Name">StudForgeMap</string></Properties>
      ${mapParts(genre)}
    </Item>
    <Item class="SpawnLocation" referent="${id()}">
      <Properties>
        <string name="Name">SpawnLocation</string>
        <bool name="Anchored">true</bool>
        <bool name="Neutral">true</bool>
        ${color(255, 176, 60)}
        ${vec(6, 1, 6)}
        ${cf(0, 2.5, 0)}
      </Properties>
    </Item>
  </Item>
  <Item class="Lighting" referent="${id()}">
    <Properties><string name="Name">Lighting</string></Properties>
  </Item>
  <Item class="ServerScriptService" referent="${id()}">
    <Properties><string name="Name">ServerScriptService</string></Properties>
    <Item class="Script" referent="${id()}">
      <Properties>
        <string name="Name">StudForgeGame</string>
        <ProtectedString name="Source"><![CDATA[${cdata(server)}]]></ProtectedString>
      </Properties>
    </Item>
  </Item>
  <Item class="StarterPlayer" referent="${id()}">
    <Properties><string name="Name">StarterPlayer</string></Properties>
    <Item class="StarterPlayerScripts" referent="${id()}">
      <Properties><string name="Name">StarterPlayerScripts</string></Properties>
      <Item class="LocalScript" referent="${id()}">
        <Properties>
          <string name="Name">StatusBanner</string>
          <ProtectedString name="Source"><![CDATA[${cdata(client)}]]></ProtectedString>
        </Properties>
      </Item>
    </Item>
  </Item>
</roblox>
`;
}

function checkRbxlx(xml, genre) {
  const errors = [];
  if (!xml.includes("<roblox")) errors.push("missing roblox root");
  for (const token of ["Workspace", "SpawnLocation", "ServerScriptService", "LocalScript", "StudForgeMap", genre]) {
    if (!xml.includes(token)) errors.push("missing " + token);
  }
  if ((xml.match(/<Item /g) || []).length < 8) errors.push("too few items");
  return errors;
}

if (typeof module !== "undefined" && module.exports) {
  module.exports = { buildRbxlx, checkRbxlx };
}

if (typeof require === "function" && require.main === module) {
  const fs = require("fs");
  const path = require("path");
  const out = path.join(__dirname, "places");
  fs.mkdirSync(out, { recursive: true });
  const genres = ["obby", "tycoon", "simulator", "horror", "race", "arena"];
  let failed = 0;
  for (const genre of genres) {
    const xml = buildRbxlx("Test " + genre, genre, "place file test");
    const errors = checkRbxlx(xml, genre);
    fs.writeFileSync(path.join(out, genre + ".rbxlx"), xml);
    if (errors.length) {
      failed += 1;
      console.log("FAIL", genre, errors.join("; "));
    } else {
      console.log("PASS", genre, xml.length, "bytes");
    }
  }
  if (failed) process.exit(1);
  console.log("PLACE FILES OK");
}
