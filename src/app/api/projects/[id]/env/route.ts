import { NextRequest, NextResponse } from 'next/server'
import { validateSession } from '@/lib/auth'
import { updateProjectEnvVars } from '@/lib/project'
import { prisma } from '@/lib/db'

interface RouteContext {
  params: Promise<{
    id: string
  }>
}

export async function GET(request: NextRequest, { params }: RouteContext) {
  const { id } = await params
  try {
    const sessionToken = request.cookies.get('session')?.value
    
    if (!sessionToken) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    const session = await validateSession(sessionToken)
    if (!session) {
      return NextResponse.json(
        { error: 'Invalid session' },
        { status: 401 }
      )
    }

    // Fetch project environment variables from database
    const envVars = await prisma.projectEnvVar.findMany({
      where: { projectId: id }
    })

    // Convert to object format
    const envVarsObject: Record<string, string> = {}
    envVars.forEach((envVar: { key: string; value: string }) => {
      envVarsObject[envVar.key] = envVar.value
    })

    return NextResponse.json({ envVars: envVarsObject })
  } catch (error) {
    console.error('Get env vars error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest, { params }: RouteContext) {
  const { id } = await params
  try {
    const sessionToken = request.cookies.get('session')?.value
    
    if (!sessionToken) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    const session = await validateSession(sessionToken)
    if (!session) {
      return NextResponse.json(
        { error: 'Invalid session' },
        { status: 401 }
      )
    }

    const envVars = await request.json()

    if (!envVars || typeof envVars !== 'object') {
      return NextResponse.json(
        { error: 'Invalid environment variables' },
        { status: 400 }
      )
    }

    const result = await updateProjectEnvVars(id, envVars)

    if (!result.success) {
      return NextResponse.json(
        { error: result.error },
        { status: 500 }
      )
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Update env vars error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}