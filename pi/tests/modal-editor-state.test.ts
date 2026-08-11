import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
	INITIAL_NORMAL_PARSER_STATE,
	MAX_MODAL_COUNT,
	parseNormalKey,
} from "../lib/modal-editor-state.ts";
import type {
	ModalAction,
	NormalParserState,
} from "../lib/modal-editor-state.ts";

function parseKeys(keys: string): {
	readonly state: NormalParserState;
	readonly action: ModalAction | undefined;
} {
	let state = INITIAL_NORMAL_PARSER_STATE;
	let action: ModalAction | undefined;

	for (const key of keys) {
		const result = parseNormalKey(state, key);
		state = result.state;
		action = result.action ?? action;
	}

	return { state, action };
}

describe("parseNormalKey", () => {
	const directCases = [
		["h", { kind: "move", motion: "left", count: 1 }],
		["j", { kind: "move", motion: "down", count: 1 }],
		["k", { kind: "move", motion: "up", count: 1 }],
		["l", { kind: "move", motion: "right", count: 1 }],
		["w", { kind: "move", motion: "wordForward", count: 1 }],
		["b", { kind: "move", motion: "wordBackward", count: 1 }],
		["e", { kind: "move", motion: "wordEnd", count: 1 }],
		["0", { kind: "move", motion: "lineStart", count: 1 }],
		["$", { kind: "move", motion: "lineEnd", count: 1 }],
		["i", { kind: "insert", placement: "before" }],
		["a", { kind: "insert", placement: "after" }],
		["I", { kind: "insert", placement: "lineStart" }],
		["A", { kind: "insert", placement: "lineEnd" }],
		["x", { kind: "delete", target: "character", count: 1 }],
		["D", { kind: "delete", target: "lineEnd", count: 1 }],
		["C", { kind: "change", target: "lineEnd", count: 1 }],
		["u", { kind: "undo", count: 1 }],
	] as const;

	for (const [keys, expected] of directCases) {
		it(`parses ${keys}`, () => {
			assert.deepEqual(parseKeys(keys).action, expected);
		});
	}

	const countedCases = [
		["3w", { kind: "move", motion: "wordForward", count: 3 }],
		["10l", { kind: "move", motion: "right", count: 10 }],
		["4x", { kind: "delete", target: "character", count: 4 }],
		["2u", { kind: "undo", count: 2 }],
		["dw", { kind: "delete", target: "wordForward", count: 1 }],
		["d2w", { kind: "delete", target: "wordForward", count: 2 }],
		["2d3w", { kind: "delete", target: "wordForward", count: 6 }],
		["db", { kind: "delete", target: "wordBackward", count: 1 }],
		["d$", { kind: "delete", target: "lineEnd", count: 1 }],
		["2dd", { kind: "delete", target: "line", count: 2 }],
	] as const;

	for (const [keys, expected] of countedCases) {
		it(`parses ${keys}`, () => {
			assert.deepEqual(parseKeys(keys).action, expected);
		});
	}

	const additionalCountCases = [
		["3db", { kind: "delete", target: "wordBackward", count: 3 }],
		["2d$", { kind: "delete", target: "lineEnd", count: 2 }],
		["3D", { kind: "delete", target: "lineEnd", count: 3 }],
		["2C", { kind: "change", target: "lineEnd", count: 2 }],
	] as const;

	for (const [keys, expected] of additionalCountCases) {
		it(`preserves the complete count for ${keys}`, () => {
			assert.deepEqual(parseKeys(keys).action, expected);
		});
	}

	it("treats zero as a motion unless a count is already active", () => {
		assert.deepEqual(parseKeys("0").action, {
			kind: "move",
			motion: "lineStart",
			count: 1,
		});
		assert.deepEqual(parseKeys("20l").action, {
			kind: "move",
			motion: "right",
			count: 20,
		});
	});

	describe("bounded modal counts", () => {
		it("saturates a direct count above the maximum", () => {
			assert.deepEqual(parseKeys("1001w").action, {
				kind: "move",
				motion: "wordForward",
				count: MAX_MODAL_COUNT,
			});
		});

		it("saturates a multiplied operator and motion count", () => {
			assert.deepEqual(parseKeys("100d100w").action, {
				kind: "delete",
				target: "wordForward",
				count: MAX_MODAL_COUNT,
			});
		});

		it("saturates a count too long for a finite JavaScript number", () => {
			assert.deepEqual(parseKeys("9".repeat(309) + "u").action, {
				kind: "undo",
				count: MAX_MODAL_COUNT,
			});
		});

		it("preserves a count below the maximum", () => {
			assert.deepEqual(parseKeys("999x").action, {
				kind: "delete",
				target: "character",
				count: 999,
			});
		});
	});

	it("keeps an incomplete delete operator pending", () => {
		assert.deepEqual(parseKeys("2d"), {
			state: {
				status: "deletePending",
				operatorCount: 2,
				motionCountDigits: "",
			},
			action: undefined,
		});
	});

	it("clears pending input after an unsupported key", () => {
		assert.deepEqual(parseKeys("2dq"), {
			state: INITIAL_NORMAL_PARSER_STATE,
			action: undefined,
		});
	});

	it("accepts a new command after invalidating a pending operator", () => {
		const pending = parseNormalKey(INITIAL_NORMAL_PARSER_STATE, "d").state;
		const reset = parseNormalKey(pending, "q").state;
		assert.deepEqual(parseNormalKey(reset, "w").action, {
			kind: "move",
			motion: "wordForward",
			count: 1,
		});
	});
});
