// Template: DAL Layer (TypeORM)
// Location: src/dal/typeorm/feature-name-dal.ts
// Replace "FeatureName" with your actual feature name

import type { FindManyOptions } from 'typeorm'

import type {
  FeatureNameFilterModel,
  FeatureNameModel,
  FeatureNameModelCreate,
  FeatureNameModelEdit,
} from '#src/business/model/feature-name-model'
import type { IFeatureNameDal } from '#src/business/repo/feature-name-repo'
import { CommonDal } from '#src/dal/typeorm/common-dal'
import { getAppDataSource } from '#src/dal/typeorm/data-source'
import { FeatureNameEntity } from '#src/dal/typeorm/entity/feature-name-entity'

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

  findOneById = async (params: { id: string }): Promise<FeatureNameModel | undefined> => {
    const { id } = params

    const entity = await this._repository.findOne({ where: { id } })
    if (!entity) {
      return undefined
    }

    return this._entityToModel(entity)
  }

  findMany = async (params: { filter?: FeatureNameFilterModel }): Promise<FeatureNameModel[]> => {
    const { filter } = params

    const entities = await this._repository.find(this._buildFindManyOptions(filter))

    return entities.map((entity) => {
      return this._entityToModel(entity)
    })
  }

  create = async (params: FeatureNameModelCreate): Promise<FeatureNameModel> => {
    const saved = await this._repository.save(this._modelToEntity(params))

    return this._entityToModel(saved)
  }

  edit = async (params: { id: string } & FeatureNameModelEdit): Promise<FeatureNameModel> => {
    const { id, ...editData } = params

    const entity = await this._repository.findOne({ where: { id } })
    if (!entity) {
      throw new Error(`FeatureName with id ${id} not found`)
    }

    const saved = await this._repository.save({ ...entity, ...this._modelToEntity(editData) })

    return this._entityToModel(saved)
  }

  remove = async (params: { id: string }): Promise<void> => {
    const { id } = params

    await this._repository.delete(id)
  }

  protected _entityToModel = (entity: FeatureNameEntity): FeatureNameModel => {
    return {
      createdAt: entity.createdAt,
      description: entity.description ?? undefined,
      id: entity.id,
      name: entity.name,
      status: entity.status,
      updatedAt: entity.updatedAt,
    }
  }

  protected _modelToEntity = (model: Partial<FeatureNameModel>): Partial<FeatureNameEntity> => {
    return {
      description: model.description,
      id: model.id,
      name: model.name,
      status: model.status,
    }
  }

  protected _buildFindManyOptions = (filter?: FeatureNameFilterModel): FindManyOptions<FeatureNameEntity> => {
    if (!filter) {
      return {}
    }

    return { where: this._buildWhereClause(filter) }
  }

  protected _buildWhereClause = (filter: FeatureNameFilterModel): Record<string, unknown> => {
    const { status, search } = filter

    return {
      ...this._buildOptionalClause({ key: 'status', value: status }),
      ...this._buildOptionalClause({ key: 'name', value: search }),
    }
  }

  protected _buildOptionalClause = (params: { key: string; value?: unknown }): Record<string, unknown> => {
    const { key, value } = params

    if (value === undefined) {
      return {}
    }

    return { [key]: value }
  }
}
