// Template: Parser Service Layer (Singleton Object Pattern)
// Location: src/business/service/[name]-parser-service.ts
// Replace "ParserName" with your actual parser name (e.g., Regex, Date, Error)

import type { ParserNameParsed } from '#src/business/model/parser-name-model'

const PARSER_PATTERN = /^pattern_here$/

export interface ParserNameParsed {
	readonly original: string
	readonly parsed: unknown
}

export const parserNameParserService = {
	parse(params: { value: unknown }): ParserNameParsed | null {
		const { value } = params

		if (typeof value !== 'string') {
			return null
		}

		const match = PARSER_PATTERN.exec(value)
		if (!match) {
			return null
		}

		const capturedGroup = match[1]
		if (capturedGroup === undefined) {
			return null
		}

		try {
			return {
				original: value,
				parsed: this._transformCaptured(capturedGroup),
			}
		} catch {
			return null
		}
	},

	isString(params: { value: unknown }): value is string {
		const { value } = params

		if (typeof value !== 'string') {
			return false
		}

		return PARSER_PATTERN.test(value)
	},

	_transformCaptured(captured: string): unknown {
		return captured
	},
}
