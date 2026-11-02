#!/usr/bin/env node
// HiveBoss Connect plugin: starts the agent knowledge tools (agent-homes REQ-AGH33, c7).
//
// The tools are installed by the HiveBoss Connect installer into ~/.hiveboss/knowledge
// (or $HIVEBOSS_KNOWLEDGE_DIR). When they are missing or cannot start, this file
// answers as a small MCP server instead, so the session starts normally: in an agent's
// home its tools reply "knowledge tools unavailable" with the reason, and anywhere else
// it offers no tools at all. It reads nothing else and makes no network call.

import { existsSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, relative, sep } from "node:path";
import { createInterface } from "node:readline";
import { pathToFileURL } from "node:url";

export const UNAVAILABLE = "knowledge tools unavailable";
export const TOOL_NAMES = ["knowledge_search", "knowledge_save", "state_update", "knowledge_share"];

/** True when the session's folder is in an agent's home (a folder under the agents root holding AGENT.md). */
export function inAgentHome(env = process.env, cwd = process.cwd()) {
	if (env.HIVEBOSS_AGENT_HOME && !env.HIVEBOSS_AGENT_HOME.startsWith("${")) return true;
	try {
		const root = realpathSync(env.HIVEBOSS_AGENTS_ROOT || join(homedir(), "hiveboss", "agents"));
		const rel = relative(root, realpathSync(cwd));
		if (!rel || rel.startsWith("..") || isAbsolute(rel)) return false;
		return existsSync(join(root, rel.split(sep)[0], "AGENT.md"));
	} catch {
		return false;
	}
}

/** The stand-in server: tools that say why they are unavailable, or none outside an agent's home. */
export function unavailableServer(reason, offerTools) {
	const text = `${UNAVAILABLE}: ${reason}`;
	const tools = offerTools ? TOOL_NAMES.map((name) => ({ name, description: `${text}.`, inputSchema: { type: "object", properties: {}, additionalProperties: true } })) : [];
	return (msg) => {
		const reply = (result) => ({ jsonrpc: "2.0", id: msg.id, result });
		if (msg.method === "initialize") return reply({ protocolVersion: msg.params?.protocolVersion ?? "2025-06-18", capabilities: { tools: {} }, serverInfo: { name: "hiveboss-knowledge", version: "0.1.0" }, ...(offerTools ? { instructions: `${text}.` } : {}) });
		if (msg.method === "ping") return reply({});
		if (msg.method === "tools/list") return reply({ tools });
		if (msg.method === "tools/call") return reply({ content: [{ type: "text", text: `${text}.` }], isError: true });
		if (msg.id === undefined) return null;
		return { jsonrpc: "2.0", id: msg.id, error: { code: -32601, message: "Method not found" } };
	};
}

function serveFallback(reason) {
	const handle = unavailableServer(reason, inAgentHome());
	createInterface({ input: process.stdin }).on("line", (line) => {
		let msg;
		try {
			msg = JSON.parse(line);
		} catch {
			return;
		}
		const out = handle(msg);
		if (out) process.stdout.write(`${JSON.stringify(out)}\n`);
	});
}

export async function launch() {
	const server = join(process.env.HIVEBOSS_KNOWLEDGE_DIR || join(homedir(), ".hiveboss", "knowledge"), "server.mjs");
	if (!existsSync(server)) return serveFallback("they are not installed on this computer (run the HiveBoss Connect installer again)");
	try {
		const mod = await import(pathToFileURL(server).href);
		await mod.main(process.argv.slice(2));
	} catch (error) {
		serveFallback(`they could not start (${String(error?.message ?? error).slice(0, 200)})`);
	}
}

if (process.argv[1] && import.meta.url === pathToFileURL(realpathSync(process.argv[1])).href) await launch();
