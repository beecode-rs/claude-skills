// Template: Service Layer (Singleton Object Pattern)
// Location: src/business/service/feature-name-service.ts
// Replace "FeatureName" with your actual feature name

import type { FeatureNameModel, FeatureNameFilterModel } from '#src/business/model/feature-name-model'
import { featureNameRepo } from '#src/business/repo/feature-name-repo'

export const featureNameService = {
  getFeatureNameById: async (params: { id: string }): Promise<FeatureNameModel | undefined> => {
    return featureNameRepo.findOneById(params)
  },

  getFeatureNamesAll: async (params: {
    filter?: FeatureNameFilterModel
  }): Promise<FeatureNameModel[]> => {
    return featureNameRepo.findMany(params)
  },

  createFeatureName: async (params: {
    name: string
    description?: string
  }): Promise<FeatureNameModel> => {
    return featureNameRepo.create(params)
  },

  editFeatureName: async (params: {
    id: string
    name?: string
    description?: string
  }): Promise<FeatureNameModel> => {
    return featureNameRepo.update(params)
  },

  removeFeatureName: async (params: { id: string }): Promise<void> => {
    await featureNameRepo.remove(params)
  },
}
