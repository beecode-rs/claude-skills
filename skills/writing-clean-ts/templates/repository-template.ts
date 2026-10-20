// Template: Repository Layer
// Location: src/business/repo/feature-name-repo.ts
// Replace "FeatureName" with your actual feature name

import type {
  FeatureNameFilterModel,
  FeatureNameModel,
  FeatureNameModelCreate,
  FeatureNameModelEdit,
} from '#src/business/model/feature-name-model'
import { CommonRepo } from '#src/business/repo/common-repo'
import type { FeatureNameEntity } from '#src/dal/typeorm/entity/feature-name-entity'
import { FeatureNameDal } from '#src/dal/typeorm/feature-name-dal'

export interface IFeatureNameDal {
  findOneById(params: { id: string }): Promise<FeatureNameModel | undefined>
  findMany(params: { filter?: FeatureNameFilterModel }): Promise<FeatureNameModel[]>
  create(params: FeatureNameModelCreate): Promise<FeatureNameModel>
  edit(params: { id: string } & FeatureNameModelEdit): Promise<FeatureNameModel>
  remove(params: { id: string }): Promise<void>
}

export class FeatureNameRepo extends CommonRepo<FeatureNameEntity, FeatureNameModel> {
  protected readonly _dal: IFeatureNameDal

  constructor() {
    const dal = new FeatureNameDal()
    super({ dal })
    this._dal = dal
  }

  findOneById = async (params: { id: string }): Promise<FeatureNameModel | undefined> => {
    return await this._dal.findOneById(params)
  }

  findMany = async (params: { filter?: FeatureNameFilterModel }): Promise<FeatureNameModel[]> => {
    return await this._dal.findMany(params)
  }

  create = async (params: FeatureNameModelCreate): Promise<FeatureNameModel> => {
    return await this._dal.create(params)
  }

  edit = async (params: { id: string } & FeatureNameModelEdit): Promise<FeatureNameModel> => {
    return await this._dal.edit(params)
  }

  remove = async (params: { id: string }): Promise<void> => {
    await this._dal.remove(params)
  }
}
