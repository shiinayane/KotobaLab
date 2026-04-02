//
//  AppRouter.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/29.
//

import Observation

@Observable
final class AppRouter {
    var path: [AppRoute] = []
    var presentedSheet: AppSheet?
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeAll()
    }
    
    func present(sheet: AppSheet) {
        presentedSheet = sheet
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
}
