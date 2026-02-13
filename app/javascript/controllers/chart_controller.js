// Chart Controller - Chart.js integration for MEPPI Dashboard
// Handles chart lifecycle and rendering with FT design system styling
import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

export default class extends Controller {
  static values = {
    type: { type: String, default: 'line' },
    data: Array,
    options: Object
  }

  static targets = ["canvas"]

  chart = null

  connect() {
    this.renderChart()
  }

  renderChart() {
    if (!this.hasCanvasTarget) return

    const ctx = this.canvasTarget.getContext('2d')

    // Chart.js default configuration for Financial Times style
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: 'bottom',
          labels: {
            font: {
              family: "'Source Sans Pro', sans-serif",
              size: 12
            },
            color: '#5A5A5A',
            padding: 20,
            usePointStyle: true
          }
        },
        tooltip: {
          backgroundColor: 'rgba(26, 26, 26, 0.95)',
          titleFont: {
            family: "'Playfair Display', serif",
            size: 14,
            weight: 'bold'
          },
          bodyFont: {
            family: "'Source Sans Pro', sans-serif",
            size: 12
          },
          padding: 12,
          cornerRadius: 4,
          displayColors: true,
          boxPadding: 4
        }
      },
      scales: {
        x: {
          grid: {
            display: false,
            drawBorder: false
          },
          ticks: {
            font: {
              family: "'IBM Plex Mono', monospace",
              size: 11
            },
            color: '#5A5A5A'
          }
        },
        y: {
          grid: {
            color: '#E0DCC8',
            drawBorder: false
          },
          ticks: {
            font: {
              family: "'IBM Plex Mono', monospace",
              size: 11
            },
            color: '#5A5A5A',
            callback: function(value) {
              // Format currency values
              if (value >= 1000) {
                return '$' + (value / 1000).toFixed(1) + 'k'
              }
              return '$' + value
            }
          }
        }
      },
      interaction: {
        intersect: false,
        mode: 'index'
      }
    }

    // Chart colors - Financial Times palette
    const ftColors = {
      blue: '#1E50A2',
      red: '#D74850',
      green: '#2E7D32',
      amber: '#F59E0B',
      purple: '#7C3AED'
    }

    // Merge user-provided data with default colors
    const chartData = {
      ...this.dataValue,
      datasets: this.dataValue.datasets?.map((dataset, index) => ({
        ...dataset,
        borderColor: dataset.borderColor || Object.values(ftColors)[index % 5],
        backgroundColor: dataset.backgroundColor || Object.values(ftColors)[index % 5] + '20',
        borderWidth: 2,
        tension: 0.3,
        fill: dataset.fill || false
      })) || []
    }

    // Create chart instance
    this.chart = new Chart(ctx, {
      type: this.typeValue,
      data: chartData,
      options: { ...defaultOptions, ...this.optionsValue }
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }

  // Public API for updating chart data
  update(newData) {
    if (this.chart) {
      this.chart.data = newData
      this.chart.update()
    }
  }
}
