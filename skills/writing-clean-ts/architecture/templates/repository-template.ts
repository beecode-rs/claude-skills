// Template: Repository Layer
// Location: src/business/repo/feature-name-repo.ts
// Replace "FeatureName" with your actual feature name

import type { FeatureNameModel, FeatureNameFilterModel, FeatureNameCreateModel, FeatureNameUpdateModel } from '#src/business/model/feature-name-model'
import { CommonRepo } from '#src/business/repo/common-repo'
import { FeatureNameDal, type IFeatureNameDal } from '#src/dal/typeorm/feature-name-dal'
import { FeatureNameEntity } from '#src/dal/typeorm/entity/feature-name-entity'

export interface IFeatureNameRepo {
  findOneById(params: { id: string }): Promise<FeatureNameModel | undefined>
  findMany(params: { filter?: FeatureNameFilterModel }): Promise<FeatureNameModel[]>
  create(params: FeatureNameCreateModel): Promise<FeatureNameModel>
  update(params: { id: string } & FeatureNameUpdateModel): Promise<FeatureNameModel>
  remove(params: { id: string }): Promise<void>
}

export class FeatureNameRepo
  extends CommonRepo<FeatureNameEntity, FeatureNameModel>
  implements IFeatureNameRepo
{
  constructor(protected _dal: IFeatureNameDal = new FeatureNameDal()) {
    super({ dal: _dal })
  }

  findOneById = async (params: { id: string }): Promise<FeatureNameModel | undefined> => {
    return this._dal.findOneById(params)
  }

  findMany = async (params: { filter?: FeatureNameFilterModel }): Promise<FeatureNameModel[]> => {
    return this._dal.findMany(params)
  }

  create = async (params: FeatureNameCreateModel): Promise<FeatureNameModel> => {
    return this._dal.create(params)
  }

  update = async (params: { id: string } & FeatureNameUpdateModel): Promise<FeatureNameModel> => {
    return this._dal.update(params)
  }

  remove = async (params: { id: string }): Promise<void> => {
    await this._dal.remove(params)
  }
}
