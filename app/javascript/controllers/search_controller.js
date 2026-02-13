// Search Controller - Semantic search integration
// Handles search input and turbo-stream response rendering
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "loading"]
  static values = {
    url: { type: String, default: "/api/v1/semantic_search" },
    minLength: { type: Number, default: 2 }
  }

  search(event) {
    // Check if Enter key was pressed or form was submitted
    if (event.type === 'keydown' && event.key !== 'Enter') return
    if (event.type === 'keydown') {
      event.preventDefault()
    }

    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) return

    this.showLoading()

    fetch(this.urlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': this.getMetaContent('csrf-token')
      },
      body: JSON.stringify({
        query: query,
        limit: 10
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`Search failed: ${response.statusText}`)
      }
      return response.json()
    })
    .then(data => {
      this.renderResults(data)
      this.hideLoading()
    })
    .catch(error => {
      console.error('Search failed:', error)
      this.showError(error.message)
      this.hideLoading()
    })
  }

  renderResults(data) {
    if (!this.hasResultsTarget) return

    if (!data.data || data.data.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="text-center py-8">
          <svg class="mx-auto w-12 h-12 text-text-tertiary mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <p class="font-body text-text-secondary">No results found for "${this.inputTarget.value}"</p>
          <p class="font-body text-sm text-text-tertiary mt-2">Try different keywords or check spelling</p>
        </div>
      `
      return
    }

    const resultsHtml = data.data.map((phone, index) => {
      const similarity = (phone.similarity * 100).toFixed(1)

      return `
        <div class="bg-bg-primary border border-border-color rounded p-4 hover:shadow-card-hover transition-shadow duration-150">
          <div class="flex justify-between items-start">
            <div class="flex-1">
              <h3 class="font-display text-lg font-semibold text-text-primary mb-1">
                ${phone.full_name || phone.brand + ' ' + (phone.model || '')}
              </h3>
              <p class="font-body text-sm text-text-secondary mb-2">
                ${phone.brand} ${phone.model || ''}
              </p>
              <div class="flex items-center gap-4">
                <span class="badge badge--status-normal">
                  #${index + 1} Match
                </span>
                <span class="font-mono text-xs text-text-tertiary">
                  ${similarity}% similar
                </span>
              </div>
            </div>
          </div>
          ${phone.display_size ? `
            <div class="mt-3 pt-3 border-t border-border-color">
              <p class="font-body text-xs text-text-tertiary">
                Display: ${phone.display_size} • Storage: ${phone.storage || 'N/A'}
              </p>
            </div>
          ` : ''}
        </div>
      `
    }).join('')

    this.resultsTarget.innerHTML = `
      <div class="space-y-4">
        <h3 class="font-display text-xl font-bold text-text-primary mb-4">
          Search Results (${data.data.length})
        </h3>
        ${resultsHtml}
      </div>
    `
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = `
        <div class="flex items-center justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-accent-blue"></div>
          <span class="ml-3 font-body text-text-secondary">Searching...</span>
        </div>
      `
    }
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
  }

  showError(message) {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = `
        <div class="bg-accent-red/10 border border-accent-red rounded p-6 text-center">
          <svg class="mx-auto w-12 h-12 text-accent-red mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <p class="font-body text-accent-red font-medium mb-1">Search Error</p>
          <p class="font-body text-sm text-text-secondary">${message}</p>
        </div>
      `
    }
  }

  getMetaContent(name) {
    const meta = document.querySelector(`meta[name="${name}"]`)
    return meta ? meta.getAttribute('content') : null
  }

  onEnter(event) {
    if (event.key === 'Enter') {
      this.search(event)
    }
  }
}
