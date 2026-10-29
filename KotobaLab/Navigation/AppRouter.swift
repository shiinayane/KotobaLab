//
//  AppRouter.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/03/29.
//

import Observation

@Observable final class AppRouter {
    var presentedSheet: AppSheet?

    func present(sheet: AppSheet) {
        presentedSheet = sheet
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}
