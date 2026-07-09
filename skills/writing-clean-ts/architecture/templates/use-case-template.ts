// Template: Use Case Layer
// Location: src/business/use-case/feature-name-use-case.ts
// Use cases orchestrate multiple services/repositories for complex operations
// A use-case must orchestrate TWO OR MORE steps. Never wrap a single service call - if there is only one step, the controller calls that service directly
// Replace "FeatureName" with your actual feature name

import type { FeatureNameModel } from '#src/business/model/feature-name-model'
import { featureNameService } from '#src/business/service/feature-name-service'
import { auditLogService } from '#src/business/service/audit-log-service'
import { notificationService } from '#src/business/service/notification-service'

export const featureNameUseCase = {
  createFeatureNameWithNotification: async (params: {
    name: string
    description?: string
    userId: string
  }): Promise<FeatureNameModel> => {
    const featureName = await featureNameService.createFeatureName({
      name: params.name,
      description: params.description,
    })

    await auditLogService.createLog({
      action: 'create',
      entityType: 'featureName',
      entityId: featureName.id,
      userId: params.userId,
    })

    await notificationService.sendNotification({
      userId: params.userId,
      type: 'featureNameCreated',
      data: { featureNameId: featureName.id },
    })

    return featureName
  },

  archiveFeatureName: async (params: {
    id: string
    userId: string
  }): Promise<FeatureNameModel> => {
    const featureName = await featureNameService.editFeatureName({
      id: params.id,
      status: 'archived',
    })

    await auditLogService.createLog({
      action: 'archive',
      entityType: 'featureName',
      entityId: params.id,
      userId: params.userId,
    })

    return featureName
  },
}
