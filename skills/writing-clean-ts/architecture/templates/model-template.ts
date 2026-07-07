// Template: Model Definitions
// Location: src/business/model/feature-name-model.ts
// Replace "FeatureName" with your actual feature name

export interface FeatureNameModel {
  id: string
  name: string
  description: string | null
  status: 'active' | 'inactive' | 'archived'
  createdAt: number
  updatedAt: number
}

export interface FeatureNameCreateModel {
  name: string
  description?: string
}

export interface FeatureNameUpdateModel {
  name?: string
  description?: string | null
  status?: 'active' | 'inactive' | 'archived'
}

export interface FeatureNameFilterModel {
  status?: 'active' | 'inactive' | 'archived'
  search?: string
  createdAfter?: number
}
