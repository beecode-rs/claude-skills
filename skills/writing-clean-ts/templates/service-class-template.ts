// Template: Service Layer (Class Pattern)
// Location: src/business/service/feature-name-service.ts
// Use class pattern when methods need to call each other via `this` or need protected `_` helpers
// Replace "FeatureName" with your actual feature name
//
// CRITICAL: Export the CLASS only, NOT an instantiated object.
// ✅ CORRECT:   export class FeatureNameService { ... }
// ❌ NEVER:     export const featureNameService = new FeatureNameService()
//
// Only when one instance must hold memory a new instance would not have, rename the file to
// feature-name-service-singleton.ts, export the class as _FeatureNameService, and add the accessor at the end:
// export const featureNameServiceSingleton = singletonPattern(() => { return new _FeatureNameService() })

import type { FeatureNameModel } from '#src/business/model/feature-name-model'
import { FeatureNameRepo } from '#src/business/repo/feature-name-repo'
import { config } from '#src/util/config'

export class FeatureNameService {
  protected readonly _secretKey: string

  public constructor(params: { secretKey: string } = { secretKey: config.featureName.secretKey }) {
    const { secretKey } = params

    this._secretKey = secretKey
  }

  public getFeatureNameById = async (params: { id: string }): Promise<FeatureNameModel | undefined> => {
    const model = await new FeatureNameRepo().findOneById(params)
    if (!model) {
      return undefined
    }

    return this._decryptSensitiveFields(model)
  }

  public createFeatureName = async (params: {
    name: string
    sensitiveData?: string
  }): Promise<FeatureNameModel> => {
    const { name, sensitiveData } = params

    return await new FeatureNameRepo().create({
      name,
      sensitiveData: this._encryptSensitiveData(sensitiveData),
    })
  }

  protected _decryptSensitiveFields = (model: FeatureNameModel): FeatureNameModel => {
    return {
      ...model,
      sensitiveData: this._decryptData(model.sensitiveData),
    }
  }

  protected _encryptSensitiveData = (data?: string): string | undefined => {
    if (!data) {
      return undefined
    }

    return `encrypted:${data}:${this._secretKey}`
  }

  protected _decryptData = (data?: string): string | undefined => {
    if (!data) {
      return undefined
    }

    return data.replace('encrypted:', '').replace(`:${this._secretKey}`, '')
  }
}
