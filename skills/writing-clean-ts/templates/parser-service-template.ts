// Template: Parser Service Layer (Plain Object Pattern)
// Location: src/business/service/[name]-parser-service.ts
// Replace "ParserName" with your actual parser name (e.g., Regex, Date, Error)
// The regex lives in src/util/constant.ts as constant.regex.parserNameRegex (key ends with Regex, named for what it matches)

import type { ParserNameParsedModel } from '#src/business/model/parser-name-model'
import { constant } from '#src/util/constant'

export const parserNameParserService = {
	parse(params: { value: unknown }): ParserNameParsedModel | undefined {
		const { value } = params

		if (typeof value !== 'string') {
			return undefined
		}

		const match = constant.regex.parserNameRegex.exec(value)
		if (!match) {
			return undefined
		}

		const capturedGroup = match[1]
		if (capturedGroup === undefined) {
			return undefined
		}

		return {
			original: value,
			parsed: capturedGroup,
		}
	},

	isString(params: { value: unknown }): boolean {
		const { value } = params

		if (typeof value !== 'string') {
			return false
		}

		return constant.regex.parserNameRegex.test(value)
	},
}
