import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { labels: Array, values: Array }

  connect() {
    this.renderChart()
  }

  async renderChart() {
    const { Chart, DoughnutController, ArcElement, Tooltip, Legend } = await import("chart.js/auto")

    const canvas = this.element.querySelector("canvas")
    if (!canvas) return

    const colors = [
      "#0d6efd", "#198754", "#ffc107", "#dc3545", "#0dcaf0",
      "#6f42c1", "#fd7e14", "#20c997", "#6610f2", "#d63384"
    ]

    new Chart(canvas, {
      type: "doughnut",
      data: {
        labels: this.labelsValue,
        datasets: [{
          data: this.valuesValue,
          backgroundColor: colors.slice(0, this.labelsValue.length)
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: { position: "bottom" },
          tooltip: {
            callbacks: {
              label: (ctx) => `${ctx.label}: ¥${ctx.raw.toLocaleString()}/月`
            }
          }
        }
      }
    })
  }
}
