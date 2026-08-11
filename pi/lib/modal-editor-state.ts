export type ModalMotion =
	| "left"
	| "down"
	| "up"
	| "right"
	| "wordForward"
	| "wordBackward"
	| "wordEnd"
	| "lineStart"
	| "lineEnd";

export type ModalAction =
	| { readonly kind: "move"; readonly motion: ModalMotion; readonly count: number }
	| { readonly kind: "insert"; readonly placement: "before" | "after" | "lineStart" | "lineEnd" }
	| { readonly kind: "delete"; readonly target: "character" | "wordForward" | "wordBackward" | "lineEnd" | "line"; readonly count: number }
	| { readonly kind: "change"; readonly target: "lineEnd"; readonly count: number }
	| { readonly kind: "undo"; readonly count: number };

export type NormalParserState =
	| { readonly status: "idle"; readonly countDigits: string }
	| {
			readonly status: "deletePending";
			readonly operatorCount: number;
			readonly motionCountDigits: string;
	  };

export type NormalParseResult = {
	readonly state: NormalParserState;
	readonly action?: ModalAction;
};

export const MAX_MODAL_COUNT = 1000;

export const INITIAL_NORMAL_PARSER_STATE: NormalParserState = {
	status: "idle",
	countDigits: "",
};

const MOTIONS = {
	h: "left",
	j: "down",
	k: "up",
	l: "right",
	w: "wordForward",
	b: "wordBackward",
	e: "wordEnd",
	$: "lineEnd",
} as const satisfies Readonly<Record<string, ModalMotion>>;

function saturateCount(count: number): number {
	if (Number.isNaN(count) || count < 1) return 1;
	return Math.min(count, MAX_MODAL_COUNT);
}

function parseCount(digits: string): number {
	return digits === "" ? 1 : saturateCount(Number.parseInt(digits, 10));
}

function completed(action: ModalAction): NormalParseResult {
	return { state: INITIAL_NORMAL_PARSER_STATE, action };
}

export function parseNormalKey(
	state: NormalParserState,
	key: string,
): NormalParseResult {
	if (state.status === "deletePending") {
		if (/^[0-9]$/.test(key) && (key !== "0" || state.motionCountDigits !== "")) {
			return {
				state: {
					...state,
					motionCountDigits: state.motionCountDigits + key,
				},
			};
		}

		const count = saturateCount(
			state.operatorCount * parseCount(state.motionCountDigits),
		);
		if (key === "d") return completed({ kind: "delete", target: "line", count });
		if (key === "w") return completed({ kind: "delete", target: "wordForward", count });
		if (key === "b") return completed({ kind: "delete", target: "wordBackward", count });
		if (key === "$") return completed({ kind: "delete", target: "lineEnd", count });
		return { state: INITIAL_NORMAL_PARSER_STATE };
	}

	if (/^[0-9]$/.test(key) && (key !== "0" || state.countDigits !== "")) {
		return { state: { status: "idle", countDigits: state.countDigits + key } };
	}

	const count = parseCount(state.countDigits);
	if (key === "0") return completed({ kind: "move", motion: "lineStart", count: 1 });
	if (key === "d") {
		return {
			state: {
				status: "deletePending",
				operatorCount: count,
				motionCountDigits: "",
			},
		};
	}
	if (key in MOTIONS) {
		return completed({
			kind: "move",
			motion: MOTIONS[key as keyof typeof MOTIONS],
			count,
		});
	}

	switch (key) {
		case "i": return completed({ kind: "insert", placement: "before" });
		case "a": return completed({ kind: "insert", placement: "after" });
		case "I": return completed({ kind: "insert", placement: "lineStart" });
		case "A": return completed({ kind: "insert", placement: "lineEnd" });
		case "x": return completed({ kind: "delete", target: "character", count });
		case "D": return completed({ kind: "delete", target: "lineEnd", count });
		case "C": return completed({ kind: "change", target: "lineEnd", count });
		case "u": return completed({ kind: "undo", count });
		default: return { state: INITIAL_NORMAL_PARSER_STATE };
	}
}
