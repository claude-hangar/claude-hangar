#!/usr/bin/env node
// ─────────────────────────────────────────────────────────────────────────
// merge-settings.js — Deep-merge Hangar template into existing settings.json
// ─────────────────────────────────────────────────────────────────────────
// Usage: node merge-settings.js <existing> <template> <output>
//
// Merge strategy:
//   hooks     → append Hangar hooks to each event (skip duplicates by command)
//   mcpServers → add missing servers (don't overwrite user-configured ones)
//   env       → add missing keys (don't overwrite user values)
//   scalars   → keep user values if present (language, effortLevel, etc.)
//   statusLine → keep user value if present
// ─────────────────────────────────────────────────────────────────────────

const fs = require('fs');
const path = require('path');

const [,, existingPath, templatePath, outputPath] = process.argv;

if (!existingPath || !templatePath || !outputPath) {
  console.error('Usage: node merge-settings.js <existing> <template> <output>');
  process.exit(1);
}

let existing, template;
try {
  existing = JSON.parse(fs.readFileSync(existingPath, 'utf8'));
} catch (err) {
  console.error(`Error reading existing settings: ${err.message}`);
  process.exit(1);
}
try {
  template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
} catch (err) {
  console.error(`Error reading template: ${err.message}`);
  process.exit(1);
}

// ─── Hook Merging ────────────────────────────────────────────────────────

function getHookCommand(hook) {
  return hook.command || hook.url || '';
}

function mergeHookArray(existingHooks, templateHooks) {
  if (!templateHooks || templateHooks.length === 0) return existingHooks || [];
  if (!existingHooks || existingHooks.length === 0) return templateHooks;

  const result = [...existingHooks];

  for (const tGroup of templateHooks) {
    const matcher = tGroup.matcher || '';
    // Find existing group with same matcher
    const existingGroup = result.find(g => (g.matcher || '') === matcher);

    if (!existingGroup) {
      // New matcher group — add entirely
      result.push(tGroup);
    } else {
      // Merge hooks into existing group (skip duplicates by command string)
      const existingCommands = new Set(
        (existingGroup.hooks || []).map(getHookCommand)
      );
      for (const hook of (tGroup.hooks || [])) {
        if (!existingCommands.has(getHookCommand(hook))) {
          existingGroup.hooks = existingGroup.hooks || [];
          existingGroup.hooks.push(hook);
        }
      }
    }
  }

  return result;
}

function mergeHooks(existingHooks, templateHooks) {
  if (!templateHooks) return existingHooks || {};
  if (!existingHooks) return templateHooks;

  const result = { ...existingHooks };
  for (const [event, templateGroups] of Object.entries(templateHooks)) {
    result[event] = mergeHookArray(result[event], templateGroups);
  }
  return result;
}

// ─── MCP Server Merging ──────────────────────────────────────────────────

function mergeMcpServers(existingServers, templateServers) {
  if (!templateServers) return existingServers || {};
  if (!existingServers) return templateServers;

  const result = { ...existingServers };
  for (const [name, config] of Object.entries(templateServers)) {
    if (!result[name]) {
      result[name] = config;
    }
    // If server already exists, keep user's configuration
  }
  return result;
}

// ─── Env Merging ─────────────────────────────────────────────────────────

function mergeEnv(existingEnv, templateEnv) {
  if (!templateEnv) return existingEnv || {};
  if (!existingEnv) return templateEnv;

  const result = { ...existingEnv };
  for (const [key, value] of Object.entries(templateEnv)) {
    if (!(key in result)) {
      result[key] = value;
    }
  }
  return result;
}

// ─── Main Merge ──────────────────────────────────────────────────────────

const merged = { ...existing };

// Hooks: deep merge (append new hooks, keep existing)
merged.hooks = mergeHooks(existing.hooks, template.hooks);

// MCP Servers: add missing servers
merged.mcpServers = mergeMcpServers(existing.mcpServers, template.mcpServers);

// Env: add missing keys
if (template.env) {
  merged.env = mergeEnv(existing.env, template.env);
}

// Scalar settings: only set if not already present
const scalarKeys = ['language', 'alwaysThinkingEnabled', 'autoUpdatesChannel',
  'includeGitInstructions', 'effortLevel'];
for (const key of scalarKeys) {
  if (key in template && !(key in merged)) {
    merged[key] = template[key];
  }
}

// StatusLine: only set if not present
if (template.statusLine && !merged.statusLine) {
  merged.statusLine = template.statusLine;
}

// ─── Output ──────────────────────────────────────────────────────────────

const output = JSON.stringify(merged, null, 2) + '\n';
fs.writeFileSync(outputPath, output, 'utf8');

// Report what changed
const stats = {
  hooks: { added: 0, events: 0 },
  mcpServers: { added: 0 },
  env: { added: 0 },
  scalars: { added: 0 }
};

if (template.hooks) {
  for (const [event, groups] of Object.entries(template.hooks)) {
    const existingEvent = (existing.hooks || {})[event] || [];
    const mergedEvent = merged.hooks[event] || [];
    const existingCmds = new Set();
    for (const g of existingEvent) {
      for (const h of (g.hooks || [])) existingCmds.add(getHookCommand(h));
    }
    let added = 0;
    for (const g of mergedEvent) {
      for (const h of (g.hooks || [])) {
        if (!existingCmds.has(getHookCommand(h))) added++;
      }
    }
    if (added > 0) {
      stats.hooks.added += added;
      stats.hooks.events++;
    }
  }
}

if (template.mcpServers) {
  for (const name of Object.keys(template.mcpServers)) {
    if (!(existing.mcpServers || {})[name]) stats.mcpServers.added++;
  }
}

if (template.env) {
  for (const key of Object.keys(template.env)) {
    if (!(existing.env || {})[key]) stats.env.added++;
  }
}

for (const key of scalarKeys) {
  if (key in template && !(key in existing)) stats.scalars.added++;
}

console.log(JSON.stringify(stats));
