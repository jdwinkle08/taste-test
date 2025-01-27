//
//  AuthViewModel.swift
//  Taste Test
//
//  Created by Jeff Winkle on 1/26/25.
//

import SwiftUI

final class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
}
