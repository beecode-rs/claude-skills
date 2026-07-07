// Template: DAL Layer (TypeORM)
// Location: src/dal/typeorm/feature-name-dal.ts
// Replace "FeatureName" with your actual feature name

import type { FindManyOptions } from 'typeorm'
import type { FeatureNameModel, FeatureNameFilterModel, FeatureNameCreateModel, FeatureNameUpdateModel } from '#src/business/model/feature-name-model'
import { CommonDal } from '#src/dal/typeorm/common-dal'
import { FeatureNameEntity } from '#src/dal/typeorm/entity/feature-name-entity'
import { getAppDataSource } from '#src/dal/typeorm/data-source'

export interface IFeatureNameDal {
  findOneById(params: { id: string }): Promise<FeatureNameModel | null>
  findMany(params: { filter?: FeatureNameFilterModel }): Promise<FeatureNameModel[]>
  create(params: FeatureNameCreateModel): Promise<FeatureNameModel>
  update(params: { id: string } & FeatureNameUpdateModel): Promise<FeatureNameModel>
  remove(params: { id: string }): Promise<void>
}

export class FeatureNameDal
  extends CommonDal<FeatureNameEntity, FeatureNameModel>
  implements IFeatureNameDal
{
  constructor() {
    super({
      dataSource: getAppDataSource(),
      entityClass: FeatureNameEntity,
    })
  }

  findOneById = async (params: { id: string }): Promise<FeatureNameModel | null> => {
    const entity = await this._repository.findOne({
      where: { id: params.id },
    })
    if (!entity) {
      return null
    }
    return this._entityToModel(entity)
  }

  findMany = async (params: { filter?: FeatureNameFilterModel }): Promise<FeatureNameModel[]> => {
    const options: FindManyOptions<FeatureNameEntity> = {}

    if (params.filter) {
      options.where = this._buildWhereClause(params.filter)
    }

    const entities = await this._repository.find(options)
    return entities.map((entity) => this._entityToModel(entity))
  }

  create = async (params: FeatureNameCreateModel): Promise<FeatureNameModel> => {
    const entity = this._modelToEntity(params)
    const saved = await this._repository.save(entity)
    return this._entityToModel(saved)
  }

  update = async (params: { id: string } & FeatureNameUpdateModel): Promise<FeatureNameModel> => {
    const { id, ...updateData } = params
    const entity = await this._repository.findOne({ where: { id } })
    if (!entity) {
      throw new Error(`FeatureName with id ${id} not found`)
    }
    Object.assign(entity, this._modelToEntity(updateData))
    const saved = await this._repository.save(entity)
    return this._entityToModel(saved)
  }

  remove = async (params: { id: string }): Promise<void> => {
    await this._repository.delete(params.id)
  }

  protected _entityToModel = (entity: FeatureNameEntity): FeatureNameModel => {
    return {
      id: entity.id,
      name: entity.name,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    }
  }

  protected _modelToEntity = (model: Partial<FeatureNameModel>): Partial<FeatureNameEntity> => {
    return {
      id: model.id,
      name: model.name,
      description: model.description,
    }
  }

  protected _buildWhereClause = (filter: FeatureNameFilterModel) => {
    const where: Record<string, unknown> = {}

    if (filter.status) {
      where.status = filter.status
    }
    if (filter.search) {
      where.name = filter.search
    }

    return where
  }
}
