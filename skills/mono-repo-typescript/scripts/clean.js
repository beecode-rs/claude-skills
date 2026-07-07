import { rm } from 'fs/promises'
import { join } from 'path'

const packageDir = process.argv[2]
if (!packageDir) {
  console.error('Usage: clean.js <package-directory>')
  process.exit(1)
}

const distPath = join(process.cwd(), packageDir, 'dist')
await rm(distPath, { recursive: true, force: true })
console.log(`Cleaned ${distPath}`)
