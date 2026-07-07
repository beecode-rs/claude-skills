// Template: Service Layer (Class Pattern)
// Location: src/business/service/feature-name-service.ts
// Use class pattern when methods need to call each other via `this`
// Replace "FeatureName" with your actual feature name
//
// CRITICAL: Export the CLASS only, NOT an instantiated object.
// ✅ CORRECT:   export class FeatureNameService { ... }
// ❌ NEVER:     export const featureNameService = new FeatureNameService()
//
// If you need singleton behavior, use singletonPattern from @beecode/msh-util:
// export const featureNameServiceSingleton = singletonPattern(() => new FeatureNameService())

import type { FeatureNameModel } from '#src/business/model/feature-name-model'
import { featureNameRepo } from '#src/business/repo/feature-name-repo'

export class FeatureNameService {
  protected readonly _secretKey: string

  public constructor(params?: { secretKey?: string }) {
    const { secretKey = 'default-key' } = params ?? {}
    this._secretKey = secretKey
  }

  public getFeatureNameById = async (params: { id: string }): Promise<FeatureNameModel | null> => {
    const model = await featureNameRepo.findOneById(params)
    if (!model) {
      return null
    }
    return this._decryptSensitiveFields(model)
  }

  public createFeatureName = async (params: {
    name: string
    sensitiveData?: string
  }): Promise<FeatureNameModel> => {
    const encryptedData = this._encryptSensitiveData(params.sensitiveData)
    return featureNameRepo.create({
      name: params.name,
      sensitiveData: encryptedData,
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
    return data.replace(`encrypted:`, '').replace(`:${this._secretKey}`, '')
  }
}
