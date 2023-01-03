//
//  main.swift
//  MouseHook
//
//  Created by Johnson, Brad on 2023-01-01.
//

import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
