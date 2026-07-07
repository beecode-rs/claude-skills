// Template: Express Controller (GET List)
// Location: src/controller/express/feature-name/get-feature-name-all.ts
// Replace "FeatureName" with your actual feature name

import { z } from 'zod'
import { HttpUtil } from '@app/node-common/util/http-util'
import { validationUtil } from '@app/node-common/util/validation'
import { FeatureNameRepo } from '#src/business/repo/feature-name-repo'

const reqQueryParamsSchema = z.object({
  filter: z
    .object({
      status: z.enum(['active', 'inactive']).optional(),
      search: z.string().optional(),
    })
    .optional(),
  pagination: z
    .object({
      page: z.coerce.number().int().min(1).default(1),
      limit: z.coerce.number().int().min(1).max(100).default(20),
    })
    .optional(),
})

const featureNameResponseSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  description: z.string().nullable(),
  status: z.string(),
  createdAt: z.number(),
  updatedAt: z.number(),
})

const featureNameListResponseSchema = z.object({
  data: z.array(featureNameResponseSchema),
  meta: z.object({
    pagination: z.object({
      page: z.number(),
      limit: z.number(),
      total: z.number(),
      totalPages: z.number(),
    }),
  }),
})

export const getFeatureNameAll = {
  handler: new HttpUtil().expressEndPoint(async (req) => {
    const { filter, pagination } = validationUtil.parse(
      new HttpUtil().expressQueryToJsonParser(req.query),
      reqQueryParamsSchema
    )

    const result = await new FeatureNameRepo().findManyWithPagination({
      filter,
      pagination,
    })

    return result
  }),
  schema: {
    querystring: reqQueryParamsSchema,
    response: {
      200: featureNameListResponseSchema,
    },
  },
}
