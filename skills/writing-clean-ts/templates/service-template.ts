// Template: Service Layer (Plain Object Pattern)
// Location: src/business/service/feature-name-service.ts
// Replace "FeatureName" with your actual feature name

import type { FeatureNameStatus } from '#src/business/enum/feature-name-status-enum'
import type { FeatureNameFilterModel, FeatureNameModel } from '#src/business/model/feature-name-model'
import { FeatureNameRepo } from '#src/business/repo/feature-name-repo'

export const featureNameService = {
  getFeatureNameById: async (params: { id: string }): Promise<FeatureNameModel | undefined> => {
    return await new FeatureNameRepo().findOneById(params)
  },

  getFeatureNamesAll: async (params: {
    filter?: FeatureNameFilterModel
  }): Promise<FeatureNameModel[]> => {
    return await new FeatureNameRepo().findMany(params)
  },

  createFeatureName: async (params: {
    name: string
    description?: string
  }): Promise<FeatureNameModel> => {
    return await new FeatureNameRepo().create(params)
  },

  editFeatureName: async (params: {
    id: string
    name?: string
    description?: string
    status?: FeatureNameStatus
  }): Promise<FeatureNameModel> => {
    return await new FeatureNameRepo().edit(params)
  },

  removeFeatureName: async (params: { id: string }): Promise<void> => {
    await new FeatureNameRepo().remove(params)
  },
}
