#!/usr/bin/env node
// Hangar State MCP Server
// Exposes Claude Hangar configuration as read-only MCP tools
// Zero dependencies — pure Node.js

const fs = require('fs');
const path = require('path');

const CLAUDE_DIR = path.join(process.env.HOME || process.env.USERPROFILE, '.claude');

// Tool definitions
const TOOLS = [
  {
    name: 'hangar_hooks',
    description: 'List installed Claude Hangar hooks with their profiles and event types',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'hangar_skills',
    description: 'List available Claude Hangar skills with user-invocable status and argument hints',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'hangar_agents',
    description: 'List configured Claude Hangar agents with their models and descriptions',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'hangar_config',
    description: 'Read Claude Hangar defaults and current profile settings',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'hangar_freshness',
    description: 'Read the latest freshness check summary',
    inputSchema: { type: 'object', properties: {} }
  }
];

// --- Tool implementations ---

function listHooks() {
  const hooksDir = path.join(CLAUDE_DIR, 'hooks');
  try {
    const files = fs.readdirSync(hooksDir).filter(f => f.endsWith('.sh'));
    const hooks = files.map(f => {
      const content = fs.readFileSync(path.join(hooksDir, f), 'utf8');
      const trigger = (content.match(/# Trigger:\s*(.+)/i) || [])[1] || 'unknown';
      const profile = (content.match(/HOOK_MIN_PROFILE="(\w+)"/) || [])[1] || 'standard';
      return { name: f.replace('.sh', ''), trigger: trigger.trim(), profile };
    });
    return JSON.stringify(hooks, null, 2);
  } catch (e) {
    return JSON.stringify({ error: e.message });
  }
}

function listSkills() {
  const skillsDir = path.join(CLAUDE_DIR, 'skills');
  try {
    const dirs = fs.readdirSync(skillsDir, { withFileTypes: true })
      .filter(d => d.isDirectory());
    const skills = dirs.map(d => {
      const skillFile = path.join(skillsDir, d.name, 'SKILL.md');
      if (!fs.existsSync(skillFile)) return null;
      const content = fs.readFileSync(skillFile, 'utf8');
      const fm = content.match(/^---\n([\s\S]*?)\n---/);
      if (!fm) return { name: d.name };
      const yaml = fm[1];
      const desc = (yaml.match(/description:\s*(.+)/) || [])[1] || '';
      const invocable = /user_invocable:\s*true/.test(yaml);
      const argHint = (yaml.match(/argument_hint:\s*"([^"]*)"/) || [])[1] || '';
      return {
        name: d.name,
        description: desc.trim(),
        user_invocable: invocable,
        argument_hint: argHint
      };
    }).filter(Boolean);
    return JSON.stringify(skills, null, 2);
  } catch (e) {
    return JSON.stringify({ error: e.message });
  }
}

function listAgents() {
  const agentsDir = path.join(CLAUDE_DIR, 'agents');
  try {
    const files = fs.readdirSync(agentsDir).filter(f => f.endsWith('.md'));
    const agents = files.map(f => {
      const content = fs.readFileSync(path.join(agentsDir, f), 'utf8');
      const fm = content.match(/^---\n([\s\S]*?)\n---/);
      if (!fm) return { name: f.replace('.md', '') };
      const yaml = fm[1];
      const model = (yaml.match(/model:\s*(.+)/) || [])[1] || '';
      const desc = (yaml.match(/description:\s*(.+)/) || [])[1] || '';
      return { name: f.replace('.md', ''), model: model.trim(), description: desc.trim() };
    });
    return JSON.stringify(agents, null, 2);
  } catch (e) {
    return JSON.stringify({ error: e.message });
  }
}

function readConfig() {
  try {
    const defaultsPath = path.join(CLAUDE_DIR, 'lib', 'defaults.json');
    const defaults = JSON.parse(fs.readFileSync(defaultsPath, 'utf8'));
    const profile = process.env.HANGAR_HOOK_PROFILE || 'standard';
    return JSON.stringify({ currentProfile: profile, defaults }, null, 2);
  } catch (e) {
    return JSON.stringify({ error: e.message });
  }
}

function readFreshness() {
  const locations = [
    path.join(process.cwd(), '.freshness-state.json'),
    path.join(CLAUDE_DIR, '.freshness-state.json')
  ];
  for (const loc of locations) {
    try {
      const data = JSON.parse(fs.readFileSync(loc, 'utf8'));
      return JSON.stringify({
        lastCheck: data.lastCheck,
        mode: data.mode,
        summary: data.summary,
        outdated: Object.entries(data.results || {})
          .filter(([, v]) => v.status === 'outdated')
          .map(([k, v]) => ({ package: k, documented: v.documented, current: v.current }))
      }, null, 2);
    } catch {
      continue;
    }
  }
  return JSON.stringify({ error: 'No .freshness-state.json found' });
}

// Tool name → handler mapping
const HANDLER = {
  hangar_hooks: listHooks,
  hangar_skills: listSkills,
  hangar_agents: listAgents,
  hangar_config: readConfig,
  hangar_freshness: readFreshness
};

// --- MCP stdio transport (Content-Length framed JSON-RPC) ---

function send(obj) {
  const msg = JSON.stringify(obj);
  const header = `Content-Length: ${Buffer.byteLength(msg)}\r\n\r\n`;
  process.stdout.write(header + msg);
}

function handleMessage(msg) {
  const { id, method, params } = msg;

  if (method === 'initialize') {
    send({
      jsonrpc: '2.0',
      id,
      result: {
        protocolVersion: '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: 'hangar-state', version: '1.0.0' }
      }
    });
  } else if (method === 'notifications/initialized') {
    // Notification — no response needed
  } else if (method === 'tools/list') {
    send({ jsonrpc: '2.0', id, result: { tools: TOOLS } });
  } else if (method === 'tools/call') {
    const toolName = params?.name;
    const handler = HANDLER[toolName];
    if (handler) {
      const result = handler();
      send({
        jsonrpc: '2.0',
        id,
        result: { content: [{ type: 'text', text: result }] }
      });
    } else {
      send({
        jsonrpc: '2.0',
        id,
        error: { code: -32601, message: `Unknown tool: ${toolName}` }
      });
    }
  } else if (method === 'ping') {
    send({ jsonrpc: '2.0', id, result: {} });
  } else if (id !== undefined) {
    // Unknown method with an id — return method-not-found
    send({
      jsonrpc: '2.0',
      id,
      error: { code: -32601, message: `Method not found: ${method}` }
    });
  }
  // Unknown notifications (no id) are silently ignored per JSON-RPC spec
}

// Parse Content-Length delimited messages from stdin
let buffer = '';

process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => {
  buffer += chunk;
  while (true) {
    const headerEnd = buffer.indexOf('\r\n\r\n');
    if (headerEnd === -1) break;

    const header = buffer.substring(0, headerEnd);
    const match = header.match(/Content-Length:\s*(\d+)/i);
    if (!match) {
      // Malformed header — skip past it
      buffer = buffer.substring(headerEnd + 4);
      continue;
    }

    const contentLength = parseInt(match[1], 10);
    const bodyStart = headerEnd + 4;

    if (buffer.length < bodyStart + contentLength) {
      // Not enough data yet — wait for more
      break;
    }

    const body = buffer.substring(bodyStart, bodyStart + contentLength);
    buffer = buffer.substring(bodyStart + contentLength);

    try {
      handleMessage(JSON.parse(body));
    } catch (e) {
      process.stderr.write(`Parse error: ${e.message}\n`);
    }
  }
});

process.stderr.write('Hangar State MCP Server started\n');
