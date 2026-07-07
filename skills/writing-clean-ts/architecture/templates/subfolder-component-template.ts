// Template: Subfolder Component (Business Layer)
// Location: src/business/component/<folder-name>/<domain>.ts
// Example: src/business/component/yaml-parser/date.ts

// Example folder: yaml-parser
// Example domain: date
// Class name: YamlParserDate (FolderContext + Domain)
// Singleton: yamlParserDate (folderContext + Domain)

const PATTERN = /^somePattern(.*)$/

export class <FolderContextPascal><DomainPascal> {
	protected _isStringValue(value: unknown): value is string {
		return typeof value === 'string'
	}

	protected _matchesPattern(value: string): boolean {
		return PATTERN.test(value)
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
			return
		}

		const match = PATTERN.exec(value)
		if (match === null) {
			return
		}

		return this._parseFromMatch(match)
	}

	protected _parseFromMatch(match: RegExpExecArray): <ResultType> | undefined {
		const extracted = this._extractFromMatch(match)
		if (extracted === undefined) {
			return
		}

		// Transform and return result
		return extracted as <ResultType>
	}
}
