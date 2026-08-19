import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@afia/ui/src/tokens.css'
import './styles.css'
import { App } from './App'

const rootEl = document.getElementById('root')
if (rootEl !== null) {
  createRoot(rootEl).render(
    <StrictMode>
      <App />
    </StrictMode>,
  )
}
