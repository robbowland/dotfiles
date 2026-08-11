import { CustomEditor } from "@earendil-works/pi-coding-agent";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	decodeKittyPrintable,
	matchesKey,
	stripTerminalSequences,
	truncateToWidth,
	visibleWidth,
} from "@earendil-works/pi-tui";

import {
	INITIAL_NORMAL_PARSER_STATE,
	parseNormalKey,
} from "../lib/modal-editor-state.ts";
import type {
	ModalAction,
	ModalMotion,
	NormalParserState,
} from "../lib/modal-editor-state.ts";

const EDITOR_INPUT = {
	left: "\x1b[D",
	down: "\x1b[B",
	up: "\x1b[A",
	right: "\x1b[C",
	lineStart: "\x01",
	lineEnd: "\x05",
	wordBackward: "\x1bb",
	wordForward: "\x1bf",
	deleteForward: "\x1b[3~",
	deleteWordBackward: "\x17",
	deleteWordForward: "\x1bd",
	deleteLineEnd: "\x0b",
	undo: "\x1f",
} as const;

const LARGE_PASTE_MARKER = /\[paste #\d+ (?:\+\d+ lines|\d+ chars)\]/;

type PiKeybindings = ConstructorParameters<typeof CustomEditor>[2];
type EditorMode = "insert" | "normal";
type Cursor = ReturnType<CustomEditor["getCursor"]>;

function absoluteOffset(lines: readonly string[], line: number, col: number): number {
	let offset = col;
	for (let index = 0; index < line; index += 1) {
		offset += lines[index].length + 1;
	}
	return offset;
}

function cursorAtOffset(text: string, offset: number): Cursor {
	const prefix = text.slice(0, offset);
	const lines = prefix.split("\n");
	return {
		line: lines.length - 1,
		col: lines[lines.length - 1]?.length ?? 0,
	};
}

function textBetween(
	lines: readonly string[],
	start: Cursor,
	end: Cursor,
	skipCharacterAtStart: boolean,
): string {
	const text = lines.join("\n");
	let startOffset = absoluteOffset(lines, start.line, start.col);
	if (skipCharacterAtStart) {
		startOffset += [...text.slice(startOffset)][0]?.length ?? 0;
	}
	return text.slice(startOffset, absoluteOffset(lines, end.line, end.col));
}

function hasLargePasteMarker(text: string): boolean {
	return LARGE_PASTE_MARKER.test(text);
}

function isSinglePrintable(data: string): boolean {
	return /^\P{Cc}$/u.test(data);
}

function unreachable(value: never): never {
	throw new Error(`Unhandled modal editor value: ${String(value)}`);
}

class ModalEditor extends CustomEditor {
	private mode: EditorMode = "insert";
	private normalParserState: NormalParserState = INITIAL_NORMAL_PARSER_STATE;
	private readonly piKeybindings: PiKeybindings;

	constructor(
		tui: ConstructorParameters<typeof CustomEditor>[0],
		theme: ConstructorParameters<typeof CustomEditor>[1],
		keybindings: PiKeybindings,
	) {
		super(tui, theme, keybindings);
		this.piKeybindings = keybindings;
	}

	handleInput(data: string): void {
		if (matchesKey(data, "escape")) {
			if (this.mode === "insert") {
				if (this.isShowingAutocomplete()) super.handleInput(data);

				const { line, col } = this.getCursor();
				const logicalLine = this.getLines()[line] ?? "";
				if (logicalLine.length > 0 && col !== 0) {
					super.handleInput(EDITOR_INPUT.left);
				}
				this.normalParserState = INITIAL_NORMAL_PARSER_STATE;
				this.mode = "normal";
				this.tui.requestRender();
				return;
			}

			this.normalParserState = INITIAL_NORMAL_PARSER_STATE;
			super.handleInput(data);
			return;
		}

		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}

		if (
			this.piKeybindings.matches(data, "tui.input.submit")
			|| this.piKeybindings.matches(data, "app.clear")
		) {
			this.normalParserState = INITIAL_NORMAL_PARSER_STATE;
			this.mode = "insert";
			super.handleInput(data);
			this.tui.requestRender();
			return;
		}

		const key = decodeKittyPrintable(data) ?? (isSinglePrintable(data) ? data : undefined);
		if (key === undefined) {
			super.handleInput(data);
			return;
		}

		const result = parseNormalKey(this.normalParserState, key);
		this.normalParserState = result.state;
		if (result.action !== undefined) this.executeAction(result.action);
		if (this.mode === "normal") this.normalizeNormalCursor();
		this.tui.requestRender();
	}

	render(width: number): string[] {
		const lines = super.render(width);
		if (lines.length === 0) return lines;

		const label = this.mode === "insert" ? " INSERT " : " NORMAL ";
		const bottomBorderIndex = lines.findLastIndex((line) =>
			stripTerminalSequences(line).startsWith("─")
		);
		const bottomBorder = lines[bottomBorderIndex];
		if (
			bottomBorder === undefined
			|| width < label.length
			|| visibleWidth(bottomBorder) < label.length
		) {
			return lines;
		}

		lines[bottomBorderIndex] = truncateToWidth(
			bottomBorder,
			width - label.length,
			"",
		) + label;
		return lines;
	}

	private executeAction(action: ModalAction): void {
		switch (action.kind) {
			case "move":
				this.executeMovement(action.motion, action.count);
				return;
			case "insert":
				this.enterInsertMode(action.placement);
				return;
			case "delete":
				this.executeDeletion(action.target, action.count);
				return;
			case "change":
				this.executeDeletion(action.target, action.count);
				this.mode = "insert";
				return;
			case "undo":
				for (let index = 0; index < action.count; index += 1) {
					super.handleInput(EDITOR_INPUT.undo);
					this.normalizeNormalCursor();
				}
				return;
			default:
				return unreachable(action);
		}
	}

	private executeMovement(motion: ModalMotion, count: number): void {
		switch (motion) {
			case "left":
				for (let index = 0; index < count; index += 1) {
					if (this.getCursor().col === 0) return;
					super.handleInput(EDITOR_INPUT.left);
				}
				return;
			case "down":
				this.repeatEditorInput(EDITOR_INPUT.down, count);
				return;
			case "up":
				this.repeatEditorInput(EDITOR_INPUT.up, count);
				return;
			case "right":
				for (let index = 0; index < count; index += 1) {
					const { line, col } = this.getCursor();
					const logicalLine = this.getLines()[line] ?? "";
					if (logicalLine.length === 0 || col >= logicalLine.length - 1) return;
					super.handleInput(EDITOR_INPUT.right);
				}
				return;
			case "wordForward":
				this.repeatEditorInput(EDITOR_INPUT.wordForward, count);
				return;
			case "wordBackward":
				this.repeatEditorInput(EDITOR_INPUT.wordBackward, count);
				return;
			case "wordEnd":
				for (let index = 0; index < count; index += 1) this.moveWordEnd();
				return;
			case "lineStart":
				this.repeatEditorInput(EDITOR_INPUT.lineStart, count);
				return;
			case "lineEnd":
				this.repeatEditorInput(EDITOR_INPUT.lineEnd, count);
				if ((this.getLines()[this.getCursor().line] ?? "").length > 0) {
					super.handleInput(EDITOR_INPUT.left);
				}
				return;
			default:
				return unreachable(motion);
		}
	}

	private executeDeletion(
		target: Extract<ModalAction, { kind: "delete" }>["target"],
		count: number,
	): void {
		// setText clears Pi's backing data for large-paste markers.
		if (hasLargePasteMarker(this.getText())) {
			this.executeNativeDeletion(target, count);
			return;
		}

		switch (target) {
			case "character":
				this.deleteCharacters(count);
				return;
			case "wordForward":
				this.deleteByWordMovement(EDITOR_INPUT.wordForward, count);
				return;
			case "wordBackward":
				this.deleteByWordMovement(EDITOR_INPUT.wordBackward, count);
				return;
			case "lineEnd":
				this.deleteToCountedLineEnd(count);
				return;
			case "line":
				this.deleteLines(count);
				return;
			default:
				return unreachable(target);
		}
	}

	private executeNativeDeletion(
		target: Extract<ModalAction, { kind: "delete" }>["target"],
		count: number,
	): void {
		switch (target) {
			case "character":
				this.deleteCharactersNatively(count);
				return;
			case "wordForward":
				this.repeatEditorInput(EDITOR_INPUT.deleteWordForward, count);
				return;
			case "wordBackward":
				this.repeatEditorInput(EDITOR_INPUT.deleteWordBackward, count);
				return;
			case "lineEnd":
				this.deleteToCountedLineEndNatively(count);
				return;
			case "line":
				this.deleteLinesNatively(count);
				return;
			default:
				return unreachable(target);
		}
	}

	private deleteCharactersNatively(count: number): void {
		for (let index = 0; index < count; index += 1) {
			const { line, col } = this.getCursor();
			const logicalLine = this.getLines()[line] ?? "";
			if (col >= logicalLine.length) return;
			super.handleInput(EDITOR_INPUT.deleteForward);
		}
	}

	private deleteToCountedLineEndNatively(count: number): void {
		const { line, col } = this.getCursor();
		if (col < (this.getLines()[line] ?? "").length) {
			super.handleInput(EDITOR_INPUT.deleteLineEnd);
		}

		for (let index = 1; index < count; index += 1) {
			const cursor = this.getCursor();
			const lines = this.getLines();
			if (cursor.line >= lines.length - 1) return;

			super.handleInput(EDITOR_INPUT.deleteLineEnd);
			const mergedLine = this.getLines()[this.getCursor().line] ?? "";
			if (this.getCursor().col < mergedLine.length) {
				super.handleInput(EDITOR_INPUT.deleteLineEnd);
			}
		}
	}

	private deleteLinesNatively(count: number): void {
		const lines = this.getLines();
		const cursor = this.getCursor();
		const deletesThroughEnd = cursor.line + count >= lines.length;
		super.handleInput(EDITOR_INPUT.lineStart);

		if (deletesThroughEnd && cursor.line > 0) {
			super.handleInput(EDITOR_INPUT.deleteWordBackward);
			this.deleteCurrentLineEndNatively();
			for (let index = 1; index < count; index += 1) {
				if (this.getCursor().line >= this.getLines().length - 1) return;
				super.handleInput(EDITOR_INPUT.deleteLineEnd);
				this.deleteCurrentLineEndNatively();
			}
			return;
		}

		for (let index = 0; index < count; index += 1) {
			this.deleteCurrentLineEndNatively();
			if (this.getCursor().line >= this.getLines().length - 1) return;
			super.handleInput(EDITOR_INPUT.deleteLineEnd);
		}
	}

	private deleteCurrentLineEndNatively(): void {
		const { line, col } = this.getCursor();
		if (col < (this.getLines()[line] ?? "").length) {
			super.handleInput(EDITOR_INPUT.deleteLineEnd);
		}
	}

	private deleteCharacters(count: number): void {
		const lines = this.getLines();
		const start = this.getCursor();
		for (let index = 0; index < count; index += 1) {
			const before = this.getCursor();
			const logicalLine = lines[before.line] ?? "";
			if (before.line !== start.line || before.col >= logicalLine.length) break;

			super.handleInput(EDITOR_INPUT.right);
			const after = this.getCursor();
			if (after.line !== start.line || this.cursorsEqual(before, after)) break;
		}

		const end = this.getCursor();
		this.restoreCursor(start);
		this.replaceRange(lines, start, end);
	}

	private deleteByWordMovement(data: string, count: number): void {
		const lines = this.getLines();
		const start = this.getCursor();
		this.repeatEditorInput(data, count);
		const end = this.getCursor();
		this.restoreCursor(start);
		this.replaceRange(lines, start, end);
	}

	private deleteToCountedLineEnd(count: number): void {
		const lines = this.getLines();
		const start = this.getCursor();
		const endLine = Math.min(start.line + count - 1, lines.length - 1);
		const end = { line: endLine, col: lines[endLine]?.length ?? 0 };
		this.replaceRange(lines, start, end);
	}

	private deleteLines(count: number): void {
		const lines = this.getLines();
		const cursor = this.getCursor();
		const endLine = Math.min(cursor.line + count, lines.length);

		if (endLine < lines.length) {
			this.replaceRange(
				lines,
				{ line: cursor.line, col: 0 },
				{ line: endLine, col: 0 },
			);
			return;
		}

		if (cursor.line === 0) {
			this.replaceRange(
				lines,
				{ line: 0, col: 0 },
				{ line: lines.length - 1, col: lines[lines.length - 1]?.length ?? 0 },
			);
			return;
		}

		const previousLine = cursor.line - 1;
		this.replaceRange(
			lines,
			{ line: previousLine, col: lines[previousLine]?.length ?? 0 },
			{ line: lines.length - 1, col: lines[lines.length - 1]?.length ?? 0 },
		);
	}

	private replaceRange(
		lines: readonly string[],
		first: Cursor,
		second: Cursor,
	): void {
		const text = this.getText();
		const firstOffset = absoluteOffset(lines, first.line, first.col);
		const secondOffset = absoluteOffset(lines, second.line, second.col);
		const start = Math.min(firstOffset, secondOffset);
		const end = Math.max(firstOffset, secondOffset);
		if (start === end) return;

		const updatedText = text.slice(0, start) + text.slice(end);
		const target = cursorAtOffset(updatedText, start);
		this.setText(updatedText);
		this.restoreCursor(target);
	}

	private restoreCursor(target: Cursor): void {
		super.handleInput(EDITOR_INPUT.lineStart);
		let current = this.getCursor();
		while (current.line !== target.line) {
			const input = current.line > target.line ? EDITOR_INPUT.up : EDITOR_INPUT.down;
			const before = current;
			super.handleInput(input);
			current = this.getCursor();
			if (this.cursorsEqual(before, current)) {
				throw new Error(`Unable to restore modal cursor to line ${target.line}`);
			}
		}

		super.handleInput(EDITOR_INPUT.lineStart);
		current = this.getCursor();
		while (current.col < target.col) {
			const before = current;
			super.handleInput(EDITOR_INPUT.right);
			current = this.getCursor();
			if (current.line !== target.line || this.cursorsEqual(before, current)) {
				throw new Error(`Unable to restore modal cursor to column ${target.col}`);
			}
		}
	}

	private cursorsEqual(first: Cursor, second: Cursor): boolean {
		return first.line === second.line && first.col === second.col;
	}

	private enterInsertMode(action: Extract<ModalAction, { kind: "insert" }>["placement"]): void {
		switch (action) {
			case "before":
				break;
			case "after":
				if ((this.getLines()[this.getCursor().line] ?? "").length > 0) {
					super.handleInput(EDITOR_INPUT.right);
				}
				break;
			case "lineStart":
				super.handleInput(EDITOR_INPUT.lineStart);
				break;
			case "lineEnd":
				super.handleInput(EDITOR_INPUT.lineEnd);
				break;
			default:
				unreachable(action);
		}
		this.mode = "insert";
	}

	private moveWordEnd(): void {
		let lines = this.getLines();
		let start = this.getCursor();
		super.handleInput(EDITOR_INPUT.wordForward);
		let end = this.getCursor();
		let intervening = textBetween(lines, start, end, true);

		while (/^\s*$/.test(intervening) && (start.line !== end.line || start.col !== end.col)) {
			lines = this.getLines();
			start = end;
			super.handleInput(EDITOR_INPUT.wordForward);
			end = this.getCursor();
			intervening = textBetween(lines, start, end, false);
		}
	}

	private normalizeNormalCursor(): void {
		const { line, col } = this.getCursor();
		const logicalLine = this.getLines()[line] ?? "";
		if (logicalLine.length > 0 && col >= logicalLine.length) {
			super.handleInput(EDITOR_INPUT.left);
		}
	}

	private repeatEditorInput(data: string, count: number): void {
		for (let index = 0; index < count; index += 1) {
			super.handleInput(data);
		}
	}
}

export default function modalEditorExtension(pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		if (!ctx.hasUI) return;
		ctx.ui.setEditorComponent(
			(tui, theme, keybindings) => new ModalEditor(tui, theme, keybindings),
		);
	});
}
