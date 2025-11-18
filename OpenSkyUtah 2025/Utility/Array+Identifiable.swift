//
//  Array+Identifiable.swift
//  OpenSkyUtah 2025
//
//  Created by Stephen Liddle on 11/18/25.
//

import Foundation

extension Array where Element: Identifiable {
    func firstIndex(matching element: Element) -> Int? {
        for index in indices {
            if self[index].id == element.id {
                return index
            }
        }

        return nil
    }
}
