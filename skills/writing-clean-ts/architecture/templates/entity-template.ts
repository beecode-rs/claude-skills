// Template: Entity Layer (TypeORM)
// Location: src/dal/typeorm/entity/feature-name-entity.ts
// Replace "FeatureName" with your actual feature name

import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm'
import { typeormUtil } from '#src/dal/typeorm/util/typeorm-util'

@Entity('feature_name')
export class FeatureNameEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string

  @Column({ type: 'varchar', length: 255 })
  name!: string

  @Column({ type: 'text', nullable: true })
  description!: string | null

  @Column({ type: 'varchar', length: 50, default: 'active' })
  status!: string

  @CreateDateColumn({ ...typeormUtil.timestampColumnOptions })
  createdAt!: number

  @UpdateDateColumn({ ...typeormUtil.timestampColumnOptions })
  updatedAt!: number

  @DeleteDateColumn({ ...typeormUtil.timestampColumnOptions, nullable: true })
  deletedAt!: number | null
}
