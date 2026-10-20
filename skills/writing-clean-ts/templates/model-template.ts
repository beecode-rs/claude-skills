// Template: Model Definitions
// Location: src/business/model/feature-name-model.ts
// Replace "FeatureName" with your actual feature name

import type { FeatureNameStatus } from '#src/business/enum/feature-name-status-enum'

export type FeatureNameModel = {
  id: string
  name: string
  description?: string
  status: FeatureNameStatus
  createdAt: number
  updatedAt: number
}

export type FeatureNameModelCreate = {
  name: string
  description?: string
}

export type FeatureNameModelEdit = {
  name?: string
  description?: string
  status?: FeatureNameStatus
}

export type FeatureNameFilterModel = {
  status?: FeatureNameStatus
  search?: string
  createdAfter?: number
}
