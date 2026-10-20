// Template: React UI Component
// Location: src/ui-component/feature-name/feature-name-detail.tsx
// UI components receive props and handle presentation
// Replace "FeatureName" with your actual feature name

import React, { useEffect, useState } from 'react'
import { Box, Typography, Paper, Chip } from '@mui/material'
import { FeatureNameStatus } from '#src/business/enum/feature-name-status-enum'
import type { FeatureNameModel } from '#src/business/model/feature-name-model'
import { featureNameService } from '#src/business/service/feature-name-service'
import { LoadingSpinner } from '#src/ui-component/common/loading-spinner'
import { ErrorView } from '#src/ui-component/common/error-view'

type FeatureNameDetailProps = {
  featureNameId: string
}

export const FeatureNameDetail = (props: FeatureNameDetailProps): React.ReactElement => {
  const { featureNameId } = props

  const resolveErrorMessage = (err: unknown): string => {
    if (err instanceof Error) {
      return err.message
    }

    return 'Failed to load feature'
  }

  const resolveStatusColor = (status: FeatureNameStatus): 'success' | 'default' => {
    if (status === FeatureNameStatus.ACTIVE) {
      return 'success'
    }

    return 'default'
  }

  const [featureName, setFeatureName] = useState<FeatureNameModel | undefined>(undefined)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | undefined>(undefined)

  useEffect(() => {
    const loadFeatureName = async () => {
      setIsLoading(true)
      setError(undefined)

      try {
        const result = await featureNameService.getFeatureNameById({
          id: featureNameId,
        })

        if (!result) {
          setError('Feature not found')
          return
        }

        setFeatureName(result)
      } catch (err) {
        setError(resolveErrorMessage(err))
      } finally {
        setIsLoading(false)
      }
    }

    loadFeatureName()
  }, [featureNameId])

  if (isLoading) {
    return <LoadingSpinner />
  }

  if (error) {
    return <ErrorView message={error} />
  }

  if (!featureName) {
    return <ErrorView message="Feature not found" />
  }

  return (
    <Paper sx={{ p: 3 }}>
      <Box sx={{ mb: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Typography variant="h4">
          {featureName.name}
        </Typography>
        <Chip
          label={featureName.status}
          color={resolveStatusColor(featureName.status)}
        />
      </Box>

      {featureName.description && (
        <Typography variant="body1" color="text.secondary">
          {featureName.description}
        </Typography>
      )}

      <Box sx={{ mt: 3 }}>
        <Typography variant="caption" color="text.secondary">
          Created: {new Date(featureName.createdAt).toLocaleDateString()}
        </Typography>
      </Box>
    </Paper>
  )
}
