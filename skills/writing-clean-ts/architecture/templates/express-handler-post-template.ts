// Template: Express Controller (POST Create)
// Location: src/controller/express/feature-name/post-feature-name.ts
// Replace "FeatureName" with your actual feature name

import { z } from 'zod'
import { HttpUtil } from '@app/node-common/util/http-util'
import { validationUtil } from '@app/node-common/util/validation'
import { FeatureNameRepo } from '#src/business/repo/feature-name-repo'

const createFeatureNameBodySchema = z.object({
  name: z.string().min(1).max(255),
  description: z.string().max(2000).optional(),
})

const featureNameResponseSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  description: z.string().nullable(),
  status: z.string(),
  createdAt: z.number(),
  updatedAt: z.number(),
})

export const postFeatureName = {
  handler: new HttpUtil().expressEndPoint(async (req) => {
    const body = validationUtil.parse(req.body, createFeatureNameBodySchema)

    const result = await new FeatureNameRepo().create(body)

    return result
  }),
  schema: {
    body: createFeatureNameBodySchema,
    response: {
      201: featureNameResponseSchema,
    },
  },
}
