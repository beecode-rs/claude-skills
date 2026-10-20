// Template: Use Case Layer
// Location: src/business/use-case/feature-name-use-case.ts
// Use cases are stateless plain objects that orchestrate multiple services/repositories
// A use-case must orchestrate TWO OR MORE steps. Never wrap a single service call - if there is only one step, the controller calls that service directly
// Startup work is NOT a use case - it belongs in an app-boot life cycle
// Replace "FeatureName" with your actual feature name

import { AuditLogAction } from '#src/business/enum/audit-log-action-enum'
import { AuditLogEntityType } from '#src/business/enum/audit-log-entity-type-enum'
import { FeatureNameStatus } from '#src/business/enum/feature-name-status-enum'
import { NotificationType } from '#src/business/enum/notification-type-enum'
import type { FeatureNameModel } from '#src/business/model/feature-name-model'
import { auditLogService } from '#src/business/service/audit-log-service'
import { featureNameService } from '#src/business/service/feature-name-service'
import { notificationService } from '#src/business/service/notification-service'

export const featureNameUseCase = {
  createFeatureNameWithNotification: async (params: {
    name: string
    description?: string
    userId: string
  }): Promise<FeatureNameModel> => {
    const { name, description, userId } = params

    const featureName = await featureNameService.createFeatureName({ name, description })

    await auditLogService.createLog({
      action: AuditLogAction.CREATE,
      entityId: featureName.id,
      entityType: AuditLogEntityType.FEATURE_NAME,
      userId,
    })

    await notificationService.sendNotification({
      data: { featureNameId: featureName.id },
      type: NotificationType.FEATURE_NAME_CREATED,
      userId,
    })

    return featureName
  },

  archiveFeatureName: async (params: {
    id: string
    userId: string
  }): Promise<FeatureNameModel> => {
    const { id, userId } = params

    const featureName = await featureNameService.editFeatureName({
      id,
      status: FeatureNameStatus.ARCHIVED,
    })

    await auditLogService.createLog({
      action: AuditLogAction.ARCHIVE,
      entityId: id,
      entityType: AuditLogEntityType.FEATURE_NAME,
      userId,
    })

    return featureName
  },
}
