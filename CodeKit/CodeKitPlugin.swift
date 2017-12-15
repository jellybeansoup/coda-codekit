import Foundation

class CodeKitPlugin: NSObject, CodaPlugIn {

	weak var pluginsController: AnyObject?

	// MARK: Coda plug in

	required init!(plugIn aController: CodaPlugInsController!, plugInBundle: (NSObjectProtocol & CodaPlugInBundle)!) {
		self.pluginsController = aController

		super.init()

		let openProjectLabel = NSLocalizedString("Open Project", comment: "ACTION_LABEL")
		aController.registerAction(withTitle: openProjectLabel, target: self, selector: #selector(openProject))

		let buildProjectLabel = NSLocalizedString("Build Project", comment: "ACTION_LABEL")
		aController.registerAction(withTitle: buildProjectLabel, target: self, selector: #selector(buildProject))

		let previewInBrowserLabel = NSLocalizedString("Preview in Browser", comment: "ACTION_LABEL")
		aController.registerAction(withTitle: previewInBrowserLabel, target: self, selector: #selector(previewInBrowser))

		let reloadLabel = NSLocalizedString("Reload", comment: "SUBMENU_LABEL")

		let reloadBrowsersLabel = NSLocalizedString("Browsers", comment: "ACTION_LABEL")
		aController.registerAction(withTitle: reloadBrowsersLabel, underSubmenuWithTitle: reloadLabel, target: self, selector: #selector(reloadBrowsers), representedObject: nil, keyEquivalent: nil, pluginName: nil)

		let reloadStyleSheetsLabel = NSLocalizedString("StyleSheets", comment: "ACTION_LABEL")
		aController.registerAction(withTitle: reloadStyleSheetsLabel, underSubmenuWithTitle: reloadLabel, target: self, selector: #selector(reloadBrowsers), representedObject: nil, keyEquivalent: nil, pluginName: nil)
	}

	required init!(plugIn aController: CodaPlugInsController!, bundle yourBundle: Bundle!) {
		fatalError("Not compatible with this version of Coda.")
	}

	func name() -> String! {
		return NSLocalizedString("CodeKit", comment: "PLUGIN_NAME")
	}

	private var projectPath: String? {
		return pluginsController?.focusedTextView()?.path()
	}

	// MARK: Actions

	@objc private func openProject() {
		guard let path = projectPath else { return }

		compileAndRun("tell application \"CodeKit\" to select project containing path \"\(path)\"")
		compileAndRun("tell application \"CodeKit\" to activate")
	}

	@objc private func buildProject() {
		guard let path = projectPath else { return }

		compileAndRun("tell application \"CodeKit\" to build project containing path \"\(path)\"")
	}

	@objc private func previewInBrowser() {
		compileAndRun("tell application \"CodeKit\" to preview in browser")
	}

	@objc private func reloadBrowsers() {
		compileAndRun("tell application \"CodeKit\" to refresh browsers by reloading the whole page")
	}

	@objc private func reloadStyleSheets() {
		compileAndRun("tell application \"CodeKit\" to refresh browsers by reloading just stylesheets")
	}

	// MARK: Text view

	func textViewDidFocus(_ textView: CodaTextView!) {
		guard let path = textView?.path() else { return }

		compileAndRun("tell application \"CodeKit\" to select project containing path \"\(path)\"")
	}

	// MARK: Action script

	func compileAndRun(_ actionScript: String) {
		guard let scriptObject = NSAppleScript(source: actionScript) else {
			return
		}

		DispatchQueue.global(qos: .userInitiated).async { // Always execute applescript on the main queue
			var compileError: NSDictionary?
			scriptObject.compileAndReturnError(&compileError)

			if let error = compileError {
				print("The CodeKit plugin encountered an error while compiling. ActionScript: \(actionScript)\nError: \(error)")
				return
			}

			DispatchQueue.main.async { // Always execute applescript on the main queue
				var executeError: NSDictionary?
				scriptObject.executeAndReturnError(&executeError)

				if let error = executeError {
					print("The CodeKit plugin encountered an error while executing. ActionScript: \(actionScript)\nError: \(error)")
					return
				}
			}
		}
	}

}
