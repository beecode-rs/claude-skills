// Template: React Router Controller
// Location: src/controller/react-router/feature-name/detail.tsx
// Controllers extract URL params and pass to UI components
// Replace "FeatureName" with your actual feature name

import React from 'react'
import { useParams } from 'react-router-dom'
import { Box } from '@mui/material'
import { useAuth } from '#src/react-common/context/auth-context'
import { FeatureNameDetail } from '#src/ui-component/feature-name/feature-name-detail'
import { ErrorView } from '#src/ui-component/common/error-view'
import { LoadingSpinner } from '#src/ui-component/common/loading-spinner'

export const FeatureNameDetailController = (): React.ReactElement => {
  const { featureNameId } = useParams<{ featureNameId: string }>()
  const { userId, isAuthenticated } = useAuth()

  if (!isAuthenticated) {
    return <ErrorView message="Authentication required" />
  }

  if (!userId) {
    return <LoadingSpinner />
  }

  if (!featureNameId) {
    return <ErrorView message="Feature Name ID is required" />
  }

  return (
    <Box sx={{ p: 2 }}>
      <FeatureNameDetail
        featureNameId={featureNameId}
        userId={userId}
      />
    </Box>
  )
}
