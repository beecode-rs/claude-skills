import { readFile, writeFile } from 'fs/promises'
import { join } from 'path'
import { glob } from 'glob'

const packageDir = process.argv[2]
if (!packageDir) process.exit(1)

const distPath = join(process.cwd(), packageDir, 'dist')
const files = await glob(`${distPath}/**/*.js`)

for (const file of files) {
  let content = await readFile(file, 'utf-8')
  // Fix imports without extensions
  content = content.replace(
    /from ['"](\.[^'"]+)['"]/g,
    (match, p1) => {
      if (!p1.endsWith('.js')) {
        return `from '${p1}.js'`
      }
      return match
    }
  )
  await writeFile(file, content)
}

console.log(`Fixed ESM imports in ${files.length} files`)
