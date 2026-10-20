// Template: Subfolder Component (Business Layer)
// Location: src/business/component/<folder-name>/<domain>.ts
// Example: src/business/component/yaml-parser/date.ts

// Example folder: yaml-parser
// Example domain: date
// Class name: YamlParserDate (FolderContext + Domain)
// Singleton: yamlParserDate (folderContext + Domain)
// The regex lives in src/util/constant.ts (constant.regex.<whatItMatches>Regex)

import { constant } from '#src/util/constant'

export class <FolderContextPascal><DomainPascal> {
	protected _isStringValue(value: unknown): value is string {
		return typeof value === 'string'
	}

	protected _matchesPattern(value: string): boolean {
		return constant.regex.<whatItMatches>Regex.test(value)
	}

	protected _extractFromMatch(match: RegExpExecArray): string | undefined {
		return match[1]
	}

	isString(params: { value: unknown }): boolean {
		const { value } = params

		if (!this._isStringValue(value)) {
			return false
		}

		return this._matchesPattern(value)
	}

	parse(params: { value: unknown }): <ResultType> | undefined {
		const { value } = params

		if (!this._isStringValue(value)) {
			return undefined
		}

		const match = constant.regex.<whatItMatches>Regex.exec(value)
		if (match === null) {
			return undefined
		}

		return this._parseFromMatch(match)
	}

	protected _parseFromMatch(match: RegExpExecArray): <ResultType> | undefined {
		const extracted = this._extractFromMatch(match)
		if (extracted === undefined) {
			return undefined
		}

		return extracted as <ResultType>
	}
}
