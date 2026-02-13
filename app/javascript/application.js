// MEPPI Dashboard - JavaScript Application Entry Point
// Configure Stimulus controllers
import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Import all controllers
export { application }
import "controllers"
