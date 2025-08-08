//
//  ContentView.swift
//  7.1
//
//  Created by Die chen on 2025/7/1.
//

import SwiftUI
import AuthenticationServices
import CoreLocation
import Foundation
import Security

// 用户信息结构体
struct UserInfo {
    let id: String
    var fullName: String
    let email: String?
    let loginType: LoginType
    
    enum LoginType {
        case guest
        case apple
        case `internal`
    }
}

// 位置记录结构体
struct LocationRecord: Codable, Identifiable {
    let id: Int
    let objectId: String // 添加 LeanCloud 的 objectId
    let timestamp: String
    let latitude: Double
    let longitude: Double
    let accuracy: Double
    let user_id: String
    let user_name: String?
    let login_type: String?
    let user_email: String? // 新增邮箱字段
    let user_avatar: String? // 新增用户头像字段
    let device_id: String
    let client_timestamp: Double?
    let timezone: String?
    
    // 自定义初始化器
    init(id: Int, objectId: String, timestamp: String, latitude: Double, longitude: Double, accuracy: Double, user_id: String, user_name: String?, login_type: String?, user_email: String?, user_avatar: String?, device_id: String, client_timestamp: Double?, timezone: String?) {
        self.id = id
        self.objectId = objectId
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.user_id = user_id
        self.user_name = user_name
        self.login_type = login_type
        self.user_email = user_email
        self.user_avatar = user_avatar
        self.device_id = device_id
        self.client_timestamp = client_timestamp
        self.timezone = timezone
    }
}

// 钻石记录结构体
struct DiamondRecord: Codable, Identifiable {
    let id: Int
    let objectId: String // LeanCloud 的 objectId
    let user_id: String
    let user_name: String? // 用户名字段
    let user_email: String? // 新增邮箱字段
    let login_type: String // "guest" 或 "apple"
    let device_id: String? // 设备ID字段
    let diamonds: Int
    let created_at: String
    let updated_at: String
}

// 举报记录结构体
struct ReportRecord: Codable, Identifiable {
    let id: UUID
    let reportedUserId: String
    let reportedUserName: String?
    let reportedUserEmail: String?
    let reportReason: String
    let reportTime: Date
    let reporterUserId: String
    let reporterUserName: String?
    let status: String?
    
    init(reportedUserId: String, reportedUserName: String?, reportedUserEmail: String?, reportReason: String, reporterUserId: String, reporterUserName: String?, status: String? = nil) {
        self.id = UUID()
        self.reportedUserId = reportedUserId
        self.reportedUserName = reportedUserName
        self.reportedUserEmail = reportedUserEmail
        self.reportReason = reportReason
        self.reportTime = Date()
        self.reporterUserId = reporterUserId
        self.reporterUserName = reporterUserName
        self.status = status
    }
}

// 随机匹配历史记录结构体
struct RandomMatchHistory: Codable, Identifiable {
    let id: UUID
    let record: LocationRecord
    let recordNumber: Int
    let matchTime: Date
    let currentLatitude: Double?
    let currentLongitude: Double?
    
    init(record: LocationRecord, recordNumber: Int, currentLocation: CLLocationCoordinate2D?) {
        self.id = UUID()
        self.record = record
        self.recordNumber = recordNumber
        self.matchTime = Date()
        self.currentLatitude = currentLocation?.latitude
        self.currentLongitude = currentLocation?.longitude
    }
    
    var currentLocation: CLLocationCoordinate2D? {
        guard let lat = currentLatitude, let lon = currentLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// 充值界面
struct RechargeView: View {
    @ObservedObject var diamondManager: DiamondManager
    @Environment(\.dismiss) private var dismiss
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 当前钻石显示
                VStack(spacing: 10) {
                    Text("💎 当前钻石")
                        .font(.headline)
                    Text("\(diamondManager.diamonds)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.purple)
                }
                
                // 充值选项
                VStack(spacing: 20) {
                    Text("选择充值金额")
                        .font(.headline)
                    
                    VStack(spacing: 15) {
                        RechargeOption(
                            title: "1元 = 100钻石",
                            description: "推荐新手",
                            price: "¥1",
                            diamonds: 100,
                            isPopular: true,
                            isLoading: isProcessing,
                            action: { recharge(amount: 100) }
                        )
                        
                        RechargeOption(
                            title: "5元 = 550钻石",
                            description: "额外赠送50钻石",
                            price: "¥5",
                            diamonds: 550,
                            isPopular: false,
                            isLoading: isProcessing,
                            action: { recharge(amount: 550) }
                        )
                        
                        RechargeOption(
                            title: "10元 = 1200钻石",
                            description: "额外赠送200钻石",
                            price: "¥10",
                            diamonds: 1200,
                            isPopular: false,
                            isLoading: isProcessing,
                            action: { recharge(amount: 1200) }
                        )
                    }
                }
                
                Spacer()
                
                // 说明文字
                VStack(spacing: 5) {
                    Text("💡 使用说明")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("• 成功匹配时消耗1颗钻石")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("• 钻石永久有效，不会过期")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .navigationTitle("充值钻石")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func recharge(amount: Int) {
        isProcessing = true
        
        // 模拟充值过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            diamondManager.addDiamonds(amount)
            isProcessing = false
            dismiss()
        }
    }
}

// 充值选项组件
struct RechargeOption: View {
    let title: String
    let description: String
    let price: String
    let diamonds: Int
    let isPopular: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isPopular {
                            Text("热门")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.blue)
                    } else {
                        Text(price)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Text("💎 \(diamonds)")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(isLoading ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPopular ? Color.orange : Color.clear, lineWidth: 2)
            )
            .opacity(isLoading ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

// 钻石管理器
class DiamondManager: ObservableObject {
    @Published var diamonds: Int = 0
    @Published var isLoading: Bool = false
    private var currentUserId: String?
    private var currentLoginType: String?
    private var currentUserName: String?
    private var currentUserEmail: String?
    
    init() {
        // 初始化时不立即加载，需要等待用户登录
    }
    
    // 设置当前用户信息
    func setCurrentUser(userId: String, loginType: String, userName: String? = nil, userEmail: String? = nil) {
        self.currentUserId = userId
        self.currentLoginType = loginType
        self.currentUserName = userName
        self.currentUserEmail = userEmail
        loadDiamondsFromServer()
        loadUserAvatarFromServer()
    }
    
    // 从服务器加载钻石数量
    func loadDiamondsFromServer() {
        guard let userId = currentUserId, let loginType = currentLoginType else {
            return
        }
        
        isLoading = true
        
        LeanCloudService.shared.fetchDiamonds(userId: userId, loginType: loginType) { [weak self] diamondCount, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    // 如果是新用户或表不存在，创建初始钻石记录
                    if error.contains("未找到") || error.contains("Class or object doesn't exists") {
                        // 新用户初始钻石为0
                        self?.diamonds = 0
                        self?.createDiamondRecordOnServer(diamonds: 0)
                                    } else {
                    // 网络错误时显示0
                    self?.diamonds = 0
                }
                } else if let diamondCount = diamondCount {
                    // 使用服务器返回的钻石数量
                    self?.diamonds = diamondCount
                } else {
                    // 未知错误时显示0
                    self?.diamonds = 0
                }
            }
        }
    }
    
    // 从服务器加载用户头像
    func loadUserAvatarFromServer() {
        guard let userId = currentUserId, let loginType = currentLoginType else {
            return
        }
        
        LeanCloudService.shared.fetchUserAvatar(userId: userId, loginType: loginType) { [weak self] userAvatar, error in
            DispatchQueue.main.async {
                if let error = error {
                    // 如果是新用户或表不存在，使用默认头像
                    if error.contains("未找到") || error.contains("Class or object doesn't exists") {
                                            // 根据用户类型设置默认头像（使用信息确认界面的图标）
                    let defaultAvatar: String
                    switch loginType {
                    case "apple":
                        defaultAvatar = "applelogo" // Apple logo SF Symbol
                    case "internal":
                        defaultAvatar = "person.circle.fill" // 内部用户 SF Symbol
                    case "guest":
                        defaultAvatar = "person.circle.fill" // 游客 SF Symbol
                    default:
                        defaultAvatar = "person.circle.fill" // 默认 SF Symbol
                    }
                        UserDefaults.standard.set(defaultAvatar, forKey: "custom_avatar_\(userId)")
                        print("🔄 使用默认头像: \(defaultAvatar)")
                    } else {
                        // 网络错误时保持当前头像（如果有的话）
                        print("⚠️ 获取头像失败: \(error)")
                    }
                } else if let userAvatar = userAvatar {
                    // 使用服务器返回的头像
                    UserDefaults.standard.set(userAvatar, forKey: "custom_avatar_\(userId)")
                    print("🔄 从服务器加载头像: \(userAvatar)")
                } else {
                    // 未知错误时保持当前头像（如果有的话）
                    print("⚠️ 获取头像失败，未知错误")
                }
            }
        }
    }
    

    
    // 在服务器上创建钻石记录
    private func createDiamondRecordOnServer(diamonds: Int) {
        guard let userId = currentUserId, let loginType = currentLoginType else { return }
        
        // 保存当前用户名到UserDefaults，供LeanCloudService使用
        if let userName = currentUserName {
            UserDefaults.standard.set(userName, forKey: "current_user_name")
        }
        
        // 保存当前用户邮箱到UserDefaults，供LeanCloudService使用
        if let userEmail = currentUserEmail {
            UserDefaults.standard.set(userEmail, forKey: "current_user_email")
        }
        
        LeanCloudService.shared.createDiamondRecord(userId: userId, loginType: loginType, diamonds: diamonds) { success in
            // 创建钻石记录到服务器
        }
    }
    
    // 更新服务器上的钻石数量
    private func updateDiamondsOnServer() {
        guard let userId = currentUserId, let loginType = currentLoginType else { return }
        
        // 保存当前用户名到UserDefaults，供LeanCloudService使用
        if let userName = currentUserName {
            UserDefaults.standard.set(userName, forKey: "current_user_name")
        }
        
        // 保存当前用户邮箱到UserDefaults，供LeanCloudService使用
        if let userEmail = currentUserEmail {
            UserDefaults.standard.set(userEmail, forKey: "current_user_email")
        }
        
        LeanCloudService.shared.updateDiamonds(userId: userId, loginType: loginType, diamonds: diamonds) { [weak self] success in
            // 更新钻石数量到服务器
        }
    }
    
    func addDiamonds(_ amount: Int) {
        diamonds += amount
        updateDiamondsOnServer()
    }
    
    func spendDiamonds(_ amount: Int) -> Bool {
        if diamonds >= amount {
            diamonds -= amount
            updateDiamondsOnServer()
            return true
        } else {
            return false
        }
    }
    
    func hasEnoughDiamonds(_ amount: Int) -> Bool {
        return diamonds >= amount
    }
    
    // 清除用户信息（退出登录时调用）
    func clearUser() {
        currentUserId = nil
        currentLoginType = nil
        currentUserName = nil
        currentUserEmail = nil
        diamonds = 0
    }
}

// 用户状态管理器
class UserManager: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @Published var currentUser: UserInfo?
    @Published var isLoggedIn: Bool = false
    
    private let userDefaults = UserDefaults.standard
    var diamondManager: DiamondManager?
    
    override init() {
        super.init()
        loadUserFromDefaults()
    }
    
    func loginAsGuest() {
        // 获取设备唯一标识符
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        
        // 使用设备ID作为游客用户的唯一标识
        let guestID = "guest_\(deviceID)"
        
        // 尝试从本地存储获取之前保存的游客昵称
        let storedName = userDefaults.string(forKey: "guest_user_name_\(guestID)")
        
        // 生成唯一的游客用户名
        let displayName: String
        if let storedName = storedName, !storedName.isEmpty {
            displayName = storedName
        } else {
            // 生成基于设备ID的唯一游客用户名
            let shortDeviceID = String(deviceID.prefix(8))
            displayName = "游客\(shortDeviceID)"
            
            // 保存生成的用户名到本地存储
            userDefaults.set(displayName, forKey: "guest_user_name_\(guestID)")
        }
        
        let guestUser = UserInfo(
            id: guestID,
            fullName: displayName,
            email: nil,
            loginType: .guest
        )
        self.currentUser = guestUser
        self.isLoggedIn = true
        
        // 设置钻石管理器的用户信息
        diamondManager?.setCurrentUser(userId: guestID, loginType: "guest", userName: displayName, userEmail: nil)
        
    }
    
    func loginAsGuestWithInfo(displayName: String, email: String?) {
        // 获取设备唯一标识符
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        
        // 使用设备ID作为游客用户的唯一标识
        let guestID = "guest_\(deviceID)"
        
        // 使用用户提供的显示名称，如果为空则使用默认名称
        let finalDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
            "游客\(String(deviceID.prefix(8)))" : displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 保存用户提供的名称到本地存储
        userDefaults.set(finalDisplayName, forKey: "guest_user_name_\(guestID)")
        if let email = email, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userDefaults.set(email.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "guest_user_email_\(guestID)")
        }
        
        let guestUser = UserInfo(
            id: guestID,
            fullName: finalDisplayName,
            email: email?.trimmingCharacters(in: .whitespacesAndNewlines),
            loginType: .guest
        )
        self.currentUser = guestUser
        self.isLoggedIn = true
        
        // 设置钻石管理器的用户信息
        diamondManager?.setCurrentUser(userId: guestID, loginType: "guest", userName: finalDisplayName, userEmail: email?.trimmingCharacters(in: .whitespacesAndNewlines))
        
        if let email = email, !email.isEmpty {
        }
    }
    
    func loginWithApple(credential: ASAuthorizationAppleIDCredential) {
        let userID = credential.user
        let givenName = credential.fullName?.givenName ?? ""
        let familyName = credential.fullName?.familyName ?? ""
        let fullName = [givenName, familyName].filter { !$0.isEmpty }.joined(separator: " ")
        let email = credential.email
        
        // 添加详细的调试信息
        
        // 读取本地存储备用数据
        let storedName = userDefaults.string(forKey: "apple_user_name_\(userID)")
        let storedEmail = userDefaults.string(forKey: "apple_user_email_\(userID)")
        
        // 确定显示的用户名 - 优化逻辑
        var displayName: String
        
        // 检查是否是首次登录且有姓名信息
        let isFirstLoginWithName = credential.fullName != nil && !fullName.isEmpty
        
        if isFirstLoginWithName {
            // 首次登录且有姓名，使用Apple ID获取的姓名
            displayName = fullName
            userDefaults.set(fullName, forKey: "apple_user_name_\(userID)")
        } else if let storedName = storedName, !storedName.isEmpty {
            // 非首次登录或没有姓名，优先使用本地存储
            displayName = storedName
        } else if let email = email ?? storedEmail {
            // 没有姓名但有邮箱，从邮箱提取用户名
            displayName = extractUsernameFromEmail(email)
            userDefaults.set(displayName, forKey: "apple_user_name_\(userID)")
        } else {
            // 最后回退到默认名称
            displayName = "Apple用户"
        }
        
        // 邮箱处理 - 优化逻辑
        let finalEmail: String?
        if let email = email {
            // 如果Apple ID返回了邮箱，保存并使用
            finalEmail = email
            userDefaults.set(email, forKey: "apple_user_email_\(userID)")
        } else if let storedEmail = storedEmail {
            // 使用本地存储的邮箱
            finalEmail = storedEmail
        } else {
            finalEmail = nil
        }
        
        let appleUser = UserInfo(
            id: userID,
            fullName: displayName,
            email: finalEmail,
            loginType: .apple
        )
        
        self.currentUser = appleUser
        self.isLoggedIn = true
        
        // 设置钻石管理器的用户信息
        diamondManager?.setCurrentUser(userId: userID, loginType: "apple", userName: displayName, userEmail: finalEmail)
        
        // 如果首次登录但没有获取到姓名，提示用户
        if isFirstLoginWithName && fullName.isEmpty {
        }
        
        // 保存用户登录状态
        userDefaults.set(true, forKey: "is_logged_in")
        userDefaults.set("apple", forKey: "login_type")
        userDefaults.set(userID, forKey: "current_user_id")
    }
    
    private func extractUsernameFromEmail(_ email: String) -> String {
        let username = email.components(separatedBy: "@").first ?? email
        return username.isEmpty ? "Apple用户" : username
    }
    
    private func loadUserFromDefaults() {
        // 这里可以实现从本地存储恢复用户登录状态的逻辑
        // 目前暂时不实现自动登录，每次都需要重新登录
    }
    
    func updateUserName(_ newName: String) {
        guard var user = currentUser else { return }
        user.fullName = newName
        self.currentUser = user
        
        // 保存到本地存储
        if user.loginType == .apple {
            userDefaults.set(newName, forKey: "apple_user_name_\(user.id)")
        } else if user.loginType == .guest {
            userDefaults.set(newName, forKey: "guest_user_name_\(user.id)")
        }
    }
    

    
    func logout() {
        // 清除钻石管理器的用户信息
        diamondManager?.clearUser()
        
        self.currentUser = nil
        self.isLoggedIn = false
    }
    
    // 重新获取 Apple ID 信息
    func refreshAppleIDInfo() {
        guard let currentUser = currentUser, currentUser.loginType == .apple else {
            return
        }
        
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // 添加更多调试信息
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // 新增：强制刷新Apple ID信息的方法
    func forceRefreshAppleIDInfo() {
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // 测试 Apple ID 姓名获取
    func testAppleIDNameRetrieval() {
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // 检查是否需要更新 Apple ID 信息
    func checkAndUpdateAppleIDInfo() {
        guard let currentUser = currentUser, currentUser.loginType == .apple else { return }
        
        // 检查是否有设置跳转记录
        if let jumpTime = UserDefaults.standard.object(forKey: "settings_jump_time") as? Date {
            let timeSinceJump = Date().timeIntervalSince(jumpTime)
            
            // 如果距离跳转时间超过5秒，说明用户可能已经返回
            if timeSinceJump > 5 {
                refreshAppleIDInfo()
                // 清除跳转时间记录
                UserDefaults.standard.removeObject(forKey: "settings_jump_time")
            }
        }
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            loginWithApple(credential: appleIDCredential)
        } else {
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                break
            case .failed:
                break
            case .invalidResponse:
                break
            case .notHandled:
                break
            case .unknown:
                break
            case .notInteractive:
                break
            case .matchedExcludedCredential:
                break
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 获取当前窗口
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("无法获取窗口")
        }
        return window
    }
    
    // 新增：测试Apple ID信息获取的方法
    func testAppleIDInfoRetrieval() {
        
        // 检查当前用户状态
        if currentUser != nil {
            // 用户已登录
        } else {
            // 用户未登录
        }
        
        // 检查本地存储
        let userDefaults = UserDefaults.standard
        let currentUserId = userDefaults.string(forKey: "current_user_id")
        
        
        if let userId = currentUserId {
            _ = userDefaults.string(forKey: "apple_user_name_\(userId)")
            _ = userDefaults.string(forKey: "apple_user_email_\(userId)")
            // 存储信息已获取
        }
        
        // 尝试刷新Apple ID信息
        if currentUser?.loginType == .apple {
            forceRefreshAppleIDInfo()
        } else {
            // 非Apple ID用户
        }
    }
    
    // 新增：清除所有本地存储的Apple ID信息
    func clearAppleIDStoredInfo() {
        let userDefaults = UserDefaults.standard
        let currentUserId = userDefaults.string(forKey: "current_user_id")
        
        if let userId = currentUserId {
            userDefaults.removeObject(forKey: "apple_user_name_\(userId)")
            userDefaults.removeObject(forKey: "apple_user_email_\(userId)")
        }
        
        userDefaults.removeObject(forKey: "is_logged_in")
        userDefaults.removeObject(forKey: "login_type")
        userDefaults.removeObject(forKey: "current_user_id")
    }
    

    

}

// 位置管理器类
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var heading: CLHeading? // 新增：设备朝向
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // 不启动持续的方向更新，只在需要时获取
    }
    
    func requestLocation() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    func startHeadingUpdates() {
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 1 // 1度变化才回调
            locationManager.startUpdatingHeading()
        }
    }
    
    func stopHeadingUpdates() {
        locationManager.stopUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async {
            if let newLocation = locations.first {
                print("📍 位置更新成功: 纬度 \(newLocation.coordinate.latitude), 经度 \(newLocation.coordinate.longitude)")
                self.location = newLocation
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ 位置获取失败: \(error.localizedDescription)")
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    print("📍 位置权限被拒绝")
                case .locationUnknown:
                    print("📍 位置信息未知，可能正在获取中")
                case .network:
                    print("📍 网络错误，无法获取位置")
                default:
                    print("📍 其他位置错误: \(clError.code)")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            print("📍 位置权限状态变化: \(status.rawValue)")
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("📍 位置权限已授权，开始请求位置")
                self.locationManager.requestLocation()
            case .denied:
                print("📍 位置权限被拒绝")
            case .restricted:
                print("📍 位置权限受限")
            case .notDetermined:
                print("📍 位置权限未确定")
            @unknown default:
                print("📍 未知的位置权限状态")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading
        }
    }
}

struct ContentView: View {
    @StateObject private var userManager = UserManager()
    @StateObject private var locationManager = LocationManager()
    @State private var path: [String] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            if !userManager.isLoggedIn {
                LoginView(userManager: userManager, locationManager: locationManager, onLoginSuccess: {
                    // 根据登录类型决定跳转路径
                    if userManager.currentUser?.loginType == .apple {
                        path.append("userInfo")
                    } else if userManager.currentUser?.loginType == .`internal` {
                        path.append("internalUserInfo")
                    } else {
                        path.append("guestInfo")
                    }
                })
            } else {
                // 自动跳转到相应界面
                NavigationLink(value: "userInfo") {
                    EmptyView()
                }
                NavigationLink(value: "search") {
                    EmptyView()
                }
                .navigationDestination(for: String.self) { value in
                    if value == "userInfo" {
                        UserInfoConfirmView(
                            userManager: userManager,
                            onConfirm: {
                                path.append("search")
                            },
                            onBack: {
                                userManager.logout()
                            }
                        )
                        .navigationBarTitleDisplayMode(.inline)
                    } else if value == "internalUserInfo" {
                        InternalUserInfoConfirmView(
                            displayName: .constant(userManager.currentUser?.fullName ?? ""),
                            email: .constant(userManager.currentUser?.email ?? ""),
                            onConfirm: {
                                path.append("search")
                            },
                            onCancel: {
                                userManager.logout()
                            }
                        )
                    } else if value == "guestInfo" {
                        GuestInfoConfirmationView(
                            displayName: .constant(userManager.currentUser?.fullName ?? ""),
                            email: .constant(userManager.currentUser?.email ?? ""),
                            onConfirm: {
                                path.append("search")
                            },
                            onCancel: {
                                userManager.logout()
                            }
                        )
                    } else if value == "search" {
                        SearchView(
                            locationManager: locationManager,
                            userManager: userManager,
                            onBack: {
                                userManager.logout()
                            }
                        )
                        .navigationBarTitleDisplayMode(.inline)
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // 应用重新激活时检查是否需要更新 Apple ID 信息
                            userManager.checkAndUpdateAppleIDInfo()
                        }
                    }
                }
            }
        }
        .onChange(of: path) { _, newPath in
            // 当路径变化时，如果不在搜索页面或用户信息页面且用户已登录，说明用户返回了
            if newPath.isEmpty && userManager.isLoggedIn {
                userManager.logout()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // 应用即将失去焦点时，检查是否需要注销
            if userManager.isLoggedIn && path.isEmpty {
                userManager.logout()
            }
        }
        .onAppear {
            // 应用启动时不立即请求位置，避免启动延迟
        }
    }
}

struct LoginView: View {
    @ObservedObject var userManager: UserManager
    @ObservedObject var locationManager: LocationManager
    var onLoginSuccess: () -> Void = {}
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showInternalLogin = false // 新增：显示内部登录界面
    @State private var currentIcon = "🦋" // 当前显示的图标
    @State private var timer: Timer?
    @State private var showLocationIcon = true // 控制是否显示位置图标
    @State private var animationPhase = 0 // 动画阶段：0=位置图标，1=切换动画
    @State private var currentEmojiIndex = 0 // 当前emoji索引
    

    
    var body: some View {
        VStack(spacing: 30) {
                if showLocationIcon {
                    Image("位置图标")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                } else {
                    Text(EmojiList.allEmojis[currentEmojiIndex])
                        .font(.system(size: 160))
                }
                Text("Never say No")
                    .font(.system(size: 55))
                
                VStack(spacing: 15) {
                    // 游客登录按钮
                    Button(action: {
                        // 直接执行游客登录，让ContentView处理路径
                        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
                        let shortDeviceID = String(deviceID.prefix(8))
                        let guestDisplayName = "游客\(shortDeviceID)"
                        userManager.loginAsGuestWithInfo(displayName: guestDisplayName, email: "")
                        onLoginSuccess()
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                            Text("游客登录")
                        }
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    
                    // 苹果ID登录按钮
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    
                    // Apple ID 登录说明
                    Text("💡 登录后可以自定义昵称")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                }
                .padding(.horizontal, 40)
                
                // 内部账号登陆按钮 - 右下方
                HStack {
                    Spacer()
                    Button(action: {
                        showInternalLogin = true
                    }) {
                        Text("内部账号登陆")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .alert("登录提示", isPresented: $showAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showInternalLogin) {
                InternalLoginView(userManager: userManager, onLoginSuccess: onLoginSuccess)
            }
            .onAppear {
                startIconTimer()
            }
            .onDisappear {
                stopIconTimer()
            }
    }
    
    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                userManager.loginWithApple(credential: appleIDCredential)
                alertMessage = "🎉 Apple登录成功！\n欢迎 \(userManager.currentUser?.fullName ?? "用户")"
                showAlert = true
                onLoginSuccess() // 登录成功后回调
            }
        case .failure(let error):
            
            // 处理不同类型的错误
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // 用户取消登录，不显示弹窗
                    return
                case .failed:
                    alertMessage = "登录失败，请重试"
                case .invalidResponse:
                    alertMessage = "无效响应，请重试"
                case .notHandled:
                    alertMessage = "登录请求未处理"
                case .unknown:
                    alertMessage = "未知错误，请重试"
                case .notInteractive:
                    alertMessage = "登录请求非交互式"
                case .matchedExcludedCredential:
                    alertMessage = "凭证已被排除"
                @unknown default:
                    alertMessage = "登录出现问题，请重试"
                }
            } else {
                alertMessage = "登录失败: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
    
    // 启动图标切换定时器
    private func startIconTimer() {
        // 首先显示位置图标3秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showLocationIcon = false
            animationPhase = 1
            
            // 然后开始随机显示emoji，每0.3秒变化
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                currentEmojiIndex = Int.random(in: 0..<EmojiList.allEmojis.count)
            }
        }
    }
    
    // 停止图标切换定时器
    private func stopIconTimer() {
        timer?.invalidate()
        timer = nil
        // 重置状态，下次进入时重新开始
        showLocationIcon = true
        animationPhase = 0
        currentEmojiIndex = 0
    }
}

// 内部账号登录界面
struct InternalLoginView: View {
    @ObservedObject var userManager: UserManager
    var onLoginSuccess: () -> Void = {}
    
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var rememberAccount = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("内部账号登录")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("请输入内部账号和密码")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // 登录表单
                VStack(spacing: 20) {
                    // 用户名输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("账号")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入账号", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: username) { newValue in
                                // 只允许英文字母、数字和连字符
                                let filtered = newValue.filter { char in
                                    char.isLetter || char.isNumber || char == "-"
                                }
                                if filtered != newValue {
                                    username = filtered
                                }
                            }
                    }
                    
                    // 密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: password) { newValue in
                                // 密码限制：只允许字母、数字和常用特殊字符，不允许空格
                                let filtered = newValue.filter { char in
                                    char.isLetter || char.isNumber || "!@#$%^&*()_+-=[]{}|;:,.<>?".contains(char)
                                }
                                if filtered != newValue {
                                    password = filtered
                                }
                            }
                    }
                    // 记住账号选项
                    HStack {
                        Spacer()
                        HStack(alignment: .center, spacing: 6) {
                            Image(systemName: rememberAccount ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(rememberAccount ? .blue : .gray)
                                .font(.system(size: 18))
                                .onTapGesture { rememberAccount.toggle() }
                            Text("记住账号和密码")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 登录按钮
                Button(action: {
                    performInternalLogin()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text("登录")
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(username.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(username.isEmpty || password.isEmpty || isLoading)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .navigationTitle("内部登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("登录提示", isPresented: $showAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
        // 在onAppear时自动填充账号和密码
        .onAppear {
            if let savedAccount = UserDefaults.standard.string(forKey: "internal_saved_account") {
                username = savedAccount
                rememberAccount = true
                
                // 从钥匙串获取保存的密码
                if let savedPassword = getPasswordFromKeychain(username: savedAccount) {
                    password = savedPassword
                }
            }
        }
    }
    
    // 保存密码到钥匙串
    private func savePasswordToKeychain(username: String, password: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: username,
            kSecAttrServer as String: "internal_login",
            kSecValueData as String: password.data(using: .utf8)!
        ]
        
        // 先删除已存在的密码
        SecItemDelete(query as CFDictionary)
        
        // 保存新密码
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("✅ 密码已保存到钥匙串")
        } else {
            print("❌ 保存密码到钥匙串失败: \(status)")
        }
    }
    
    // 从钥匙串删除密码
    private func deletePasswordFromKeychain(username: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: username,
            kSecAttrServer as String: "internal_login"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("✅ 密码已从钥匙串删除")
        } else {
            print("❌ 从钥匙串删除密码失败: \(status)")
        }
    }
    
    // 从钥匙串获取密码
    private func getPasswordFromKeychain(username: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrAccount as String: username,
            kSecAttrServer as String: "internal_login",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let password = String(data: data, encoding: .utf8) {
            return password
        }
        return nil
    }
    
    // 执行内部登录
    private func performInternalLogin() {
        print("🔐 开始执行内部账号登录...")
        print("   📋 用户名: \(username)")
        print("   🔑 密码长度: \(password.count)")
        
        isLoading = true
        
        // 使用LeanCloud验证内部账号
        LeanCloudService.shared.verifyInternalAccount(username: username, password: password) { success, errorMessage in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    print("   ✅ 内部账号验证成功")
                    // 登录成功
                    let internalUser = UserInfo(
                        id: self.username,
                        fullName: self.username,
                        email: nil,
                        loginType: .`internal` // 使用内部用户类型
                    )
                    
                    self.userManager.currentUser = internalUser
                    self.userManager.isLoggedIn = true
                    
                    // 设置钻石管理器的用户信息，内部账号钻石余额为0
                    self.userManager.diamondManager?.setCurrentUser(userId: self.username, loginType: "internal", userName: self.username, userEmail: nil)
                    
                    print("   ✅ 内部用户登录完成，用户ID: \(internalUser.id)")
                    
                    // 获取设备ID
                    let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
                    
                    // 上传内部账号登录记录到LeanCloud
                    LeanCloudService.shared.uploadInternalLoginRecord(username: self.username, deviceId: deviceID) { success, errorMessage in
                        DispatchQueue.main.async {
                            if success {
                                print("   ✅ 内部账号登录记录上传成功")
                            } else {
                                print("   ⚠️ 内部账号登录记录上传失败: \(errorMessage ?? "未知错误")")
                                // 即使上传失败也不影响登录流程，只是记录日志
                            }
                            
                            // 无论上传是否成功，都继续登录流程
                            self.dismiss()
                            self.onLoginSuccess()
                        }
                    }
                    if rememberAccount {
                        UserDefaults.standard.set(username, forKey: "internal_saved_account")
                        // 保存密码到钥匙串
                        savePasswordToKeychain(username: username, password: password)
                    } else {
                        UserDefaults.standard.removeObject(forKey: "internal_saved_account")
                        // 从钥匙串删除密码
                        deletePasswordFromKeychain(username: username)
                    }
                } else {
                    print("   ❌ 内部账号验证失败: \(errorMessage ?? "未知错误")")
                    // 登录失败
                    self.alertMessage = errorMessage ?? "账号或密码错误，请重试"
                    self.showAlert = true
                }
            }
        }
    }
}

// 内部用户信息确认界面
struct InternalUserInfoConfirmView: View {
    @Binding var displayName: String
    @Binding var email: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @State private var editingName = false
    @State private var editingEmail = false
    @State private var showEditAlert = false
    @State private var agreedToTerms = false
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var emailFieldFocused: Bool

    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("内部用户信息确认")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            // 头像
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
                .padding(.bottom, 20)
            // 用户信息卡片
            VStack(spacing: 20) {
                // 用户名
                VStack(alignment: .leading, spacing: 8) {
                    Text("用户名")
                        .font(.headline)
                        .foregroundColor(.gray)
                    HStack {
                        if editingName {
                            TextField("请输入用户名", text: $displayName)
                                .font(.title2)
                                .fontWeight(.medium)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($nameFieldFocused)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onSubmit { editingName = false }
                                .onAppear { DispatchQueue.main.async { nameFieldFocused = true } }
                        } else {
                            Text(displayName.isEmpty ? "未填写" : displayName)
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Button(action: {
                            showEditAlert = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    Text("该名称将用于与其他用户匹配时显示")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                // 邮箱
                VStack(alignment: .leading, spacing: 8) {
                    Text("邮箱地址（可选）")
                        .font(.headline)
                        .foregroundColor(.gray)
                    HStack {
                        if editingEmail {
                            TextField("请输入邮箱地址", text: $email)
                                .font(.title2)
                                .textFieldStyle(PlainTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($emailFieldFocused)
                                .onSubmit { editingEmail = false }
                                .onAppear { DispatchQueue.main.async { emailFieldFocused = true } }
                        } else {
                            Text(email.isEmpty ? "未填写" : email)
                                .font(.title2)
                                .foregroundColor(email.isEmpty ? .gray : .blue)
                        }
                        Spacer()
                        Button(action: {
                            showEditAlert = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            Spacer()
            // 按钮区域
            VStack(spacing: 12) {
                // 协议勾选区域
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 6) {
                        Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(agreedToTerms ? .blue : .gray)
                            .font(.system(size: 18))
                            .onTapGesture { agreedToTerms.toggle() }
                        HStack(spacing: 0) {
                            Text("已阅读并同意")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button("📋 用户协议") {
                                showTermsOfService = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            Text("和")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button("📄 隐私政策") {
                                showPrivacyPolicy = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .onTapGesture { agreedToTerms.toggle() }
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                Button(action: {
                    onConfirm()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("确认并登录")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(!agreedToTerms)
                Button(action: {
                    onCancel()
                }) {
                    Text("取消")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("提示", isPresented: $showEditAlert) {
            Button("确定") { }
        } message: {
            Text("内部用户登录模式下，信息无法修改。如需修改信息，请联系管理员。")
        }
    }
}

struct SearchView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var userManager: UserManager
    @StateObject private var diamondManager = DiamondManager()
    var onBack: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var resultMessage = ""
    @State private var showAlert = false
    @State private var showLogoutAlert = false
    @State private var showEditNameAlert = false
    @State private var newUserName = ""
    @State private var showEditEmailAlert = false
    @State private var showLocationHistory = false
    @State private var locationHistory: [LocationRecord] = []
    @State private var randomRecord: LocationRecord?
    @State private var randomRecordNumber: Int = 0
    @State private var isLoadingRandomRecord = false
    @State private var randomMatchHistory: [RandomMatchHistory] = [] // 新增：随机匹配历史
    @State private var showRandomHistory = false // 新增：显示随机历史
    @State private var showRechargeAlert = false // 新增：显示充值提示
    @State private var showRechargeSheet = false // 新增：显示充值界面
    @State private var showProfileSheet = false // 新增：显示个人信息界面
    @State private var reportRecords: [ReportRecord] = [] // 新增：举报记录
    @State private var blacklistedUserIds: [String] = [] // 新增：黑名单用户ID列表
    @State private var isUserBlacklisted: Bool = false // 新增：当前用户是否在黑名单中
    @State private var blacklistExpiryTime: Date? = nil // 新增：黑名单过期时间
    @State private var timeRemaining: String = "" // 新增：剩余时间显示
    @State private var countdownTimer: Timer? = nil // 新增：倒计时定时器
    @State private var showCopySuccess = false // 新增：显示复制成功提示
    @State private var copySuccessMessage = "" // 新增：复制成功消息
    @State private var showCancelDeletionAlert = false // 新增：显示取消删除确认对话框
    @State private var pendingDeletionDate = "" // 新增：待删除日期
    @State private var showAvatarZoom = false // 新增：显示头像放大
    
    // 权限状态文本
    var authorizationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            return "未确定"
        case .restricted:
            return "受限制"
        case .denied:
            return "已拒绝"
        case .authorizedAlways:
            return "始终允许"
        case .authorizedWhenInUse:
            return "使用时允许"
        @unknown default:
            return "未知状态"
        }
    }
    
    var body: some View {
        VStack {
            // 顶部导航栏 - 用户头像、钻石显示、历史按钮和个人信息按钮
            HStack {
                // 用户头像 - 可点击放大
                Button(action: {
                    showAvatarZoom = true
                }) {
                    // 检查是否有自定义头像
                    if let userId = userManager.currentUser?.id,
                       let customAvatar = UserDefaults.standard.string(forKey: "custom_avatar_\(userId)") {
                        // 显示自定义头像
                        if customAvatar == "applelogo" {
                            // Apple logo SF Symbol
                            Image(systemName: customAvatar)
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                        } else if customAvatar == "person.circle.fill" {
                            // Person circle SF Symbol
                            Image(systemName: customAvatar)
                                .font(.system(size: 24))
                                .foregroundColor(userManager.currentUser?.loginType == .internal ? .purple : .blue)
                        } else {
                            // Emoji
                            Text(customAvatar)
                                .font(.system(size: 24))
                        }
                    } else {
                        // 显示默认头像
                        if let loginType = userManager.currentUser?.loginType {
                            if loginType == .apple {
                                Image(systemName: "applelogo")
                                    .foregroundColor(.black)
                                    .font(.system(size: 24))
                            } else if loginType == .`internal` {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 24))
                            } else {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 24))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // 用户名称 - 可点击进入个人信息
                Button(action: {
                    showProfileSheet = true
                }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(userManager.currentUser?.fullName ?? "未知用户")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // 显示用户类型
                        if let loginType = userManager.currentUser?.loginType {
                            let loginTypeText = loginType == .apple ? "Apple账户" : 
                                              loginType == .`internal` ? "内部用户" : "游客模式"
                            Text(loginTypeText)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // 钻石显示 - 可点击进入充值界面
                Button(action: {
                    showRechargeSheet = true
                }) {
                    HStack(spacing: 5) {
                        Text("💎")
                            .font(.caption)
                        if diamondManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.6)
                                .foregroundColor(.purple)
                        } else {
                            Text("\(diamondManager.diamonds)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 历史按钮
                Button(action: {
                    // 显示历史记录前先刷新黑名单
                    refreshBlacklistAndHistory()
                    showRandomHistory = true
                }) {
                    Text("历史")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                

            }
            .padding(.horizontal)
            
            // 指南针容器
            ZStack {
                // 外圈
                Circle()
                    .stroke(Color.gray, lineWidth: 3)
                    .frame(width: 250, height: 250)
                
                // 内圈
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    .frame(width: 200, height: 200)
                
                // 方向标记 - 根据设备方向旋转
                ForEach(0..<8, id: \.self) { index in
                    let angle = Double(index) * 45.0
                    let direction = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][index]
                    let color: Color = index == 0 ? .red : .black
                    let headingValue = locationManager.heading?.trueHeading ?? 0
                    
                    VStack {
                        Text(direction)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                        Spacer()
                    }
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(angle - headingValue))
                    .animation(.easeInOut(duration: 0.3), value: headingValue)
                }
                
                // 中心点
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                
                // 旋转的指针
                if let currentLocation = locationManager.location {
                    // 蓝色指针指向最新匹配的用户
                    if let latestMatch = randomMatchHistory.first {
                        let bearing = calculateBearing(from: currentLocation, to: latestMatch.record.latitude, targetLongitude: latestMatch.record.longitude)
                        let headingValue = locationManager.heading?.trueHeading ?? 0
                        let pointerAngle = (bearing - headingValue).truncatingRemainder(dividingBy: 360)
                        let displayPointerAngle = pointerAngle < 0 ? pointerAngle + 360 : pointerAngle
                        
                        Image(systemName: "location.north.fill")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .font(.system(size: 50))
                            .rotationEffect(.degrees(displayPointerAngle))
                            .animation(.easeInOut(duration: 0.3), value: displayPointerAngle)
                            .shadow(radius: 2)
                    } else {
                        // 没有匹配记录时，指针指向正北
                        let headingValue = locationManager.heading?.trueHeading ?? 0
                        Image(systemName: "location.north.fill")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .font(.system(size: 50))
                            .rotationEffect(.degrees(-headingValue))
                            .animation(.easeInOut(duration: 0.3), value: headingValue)
                            .shadow(radius: 2)
                    }
                    
                    // 显示最近3个匹配用户的彩色圆点
                    let recentMatches = Array(randomMatchHistory.prefix(3))
                    
                    // 定义3种不同的颜色（去掉红色）
                    let userColors: [Color] = [.blue, .purple, .orange]
                    
                    // 计算所有匹配用户的距离，用于比例计算
                    let matchDistances = recentMatches.compactMap { historyItem -> (id: UUID, distance: Double)? in
                        guard historyItem.currentLocation != nil else { return nil }
                        let distance = calculateDistance(from: currentLocation, to: historyItem.record.latitude, targetLongitude: historyItem.record.longitude)
                        return (historyItem.id, distance)
                    }
                    
                                         // 根据屏幕大小设置距离范围
                     let screenWidth = UIScreen.main.bounds.width
                     let screenHeight = UIScreen.main.bounds.height
                     let minScreenDimension = min(screenWidth, screenHeight)
                     
                     // 为手机和iPad设置不同的距离范围
                     let isPhone = minScreenDimension < 500 // 手机屏幕较小
                     let maxOffset: CGFloat = isPhone ? min(minScreenDimension * 0.4, 200) : min(minScreenDimension * 0.3, 300)
                     let minOffset: CGFloat = isPhone ? -120 : -150
                     let offsetRange = maxOffset - abs(minOffset)
                    
                    ForEach(Array(recentMatches.enumerated()), id: \.element.id) { index, historyItem in
                        if historyItem.currentLocation != nil {
                            let bearing = calculateBearing(from: currentLocation, to: historyItem.record.latitude, targetLongitude: historyItem.record.longitude)
                            let headingValue = locationManager.heading?.trueHeading ?? 0
                            let pointerAngle = (bearing - headingValue).truncatingRemainder(dividingBy: 360)
                            let displayPointerAngle = pointerAngle < 0 ? pointerAngle + 360 : pointerAngle
                            
                            // 计算当前用户的距离
                            let distance = calculateDistance(from: currentLocation, to: historyItem.record.latitude, targetLongitude: historyItem.record.longitude)
                            
                            // 根据所有用户的距离计算比例偏移
                            let allDistances = matchDistances.map { $0.distance }
                            let minDistance = allDistances.min() ?? 0
                            let maxDistance = allDistances.max() ?? 1
                            let distanceRange = maxDistance - minDistance
                            
                            // 计算比例位置（0-1之间）
                            let normalizedDistance = distanceRange > 0 ? (distance - minDistance) / distanceRange : 0.5
                            
                                                         // 根据比例计算偏移量，为手机提供更明显的距离差异
                             let dynamicOffset = isPhone ? 
                                 minOffset - (normalizedDistance * offsetRange * 1.5) : // 手机：增加1.5倍距离差异
                                 minOffset - (normalizedDistance * offsetRange) // iPad：保持原有比例
                            
                            // 为当前用户分配颜色
                            let userColor = userColors[index % userColors.count]
                            
                            // 彩色圆点代表历史匹配用户
                            VStack(spacing: 4) {
                                // 彩色圆点
                                Circle()
                                    .fill(userColor)
                                    .frame(width: 12, height: 12)
                                    .shadow(color: userColor.opacity(0.6), radius: 3)
                                
                                // 用户信息卡片
                                VStack(spacing: 2) {
                                    // 用户头像
                                    if let userAvatar = historyItem.record.user_avatar, !userAvatar.isEmpty {
                                        if userAvatar == "apple_logo" {
                                            // 显示Apple logo SF Symbol
                                            Image(systemName: "applelogo")
                                                .font(.system(size: 12))
                                                .foregroundColor(.black)
                                        } else {
                                            // 显示其他emoji头像
                                            Text(userAvatar)
                                                .font(.system(size: 12))
                                        }
                                    } else {
                                        // 根据用户类型显示默认头像
                                        if historyItem.record.login_type == "apple" {
                                            Image(systemName: "applelogo")
                                                .font(.system(size: 12))
                                                .foregroundColor(.black)
                                        } else if historyItem.record.login_type == "internal" {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.purple)
                                        } else {
                                            Text("👥")
                                                .font(.system(size: 12))
                                        }
                                    }
                                    
                                    Text(historyItem.record.user_name ?? "用户")
                                        .font(.caption2)
                                        .fontWeight(.black)
                                        .foregroundColor(userColor)
                                        .lineLimit(1)
                                    
                                    Text(formatDistance(distance))
                                        .font(.caption2)
                                        .foregroundColor(userColor.opacity(0.8))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(userColor.opacity(0.1))
                                .cornerRadius(6)
                                .rotationEffect(.degrees(-displayPointerAngle)) // 抵消旋转，保持文字正向
                            }
                            .offset(y: dynamicOffset) // 根据距离动态调整位置
                            .rotationEffect(.degrees(displayPointerAngle))
                            .animation(.easeInOut(duration: 0.3), value: displayPointerAngle)
                        }
                    }
                } else {
                    // 没有位置信息时，指针也根据设备方向转动
                    let headingValue = locationManager.heading?.trueHeading ?? 0
                    Image(systemName: "location.north.fill")
                        .imageScale(.large)
                        .foregroundStyle(.blue)
                        .font(.system(size: 50))
                        .rotationEffect(.degrees(-headingValue))
                        .animation(.easeInOut(duration: 0.3), value: headingValue)
                        .shadow(radius: 2)
                }
            }
            
            // 寻找按钮
            Button(action: {
                if diamondManager.hasEnoughDiamonds(1) {
                    sendLocationToServer()
                } else {
                    showRechargeSheet = true
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Text("💎")
                    }
                    Text(isLoading ? "寻找中..." : (isUserBlacklisted ? "已被禁用" : "寻找"))
                }
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(
                    isUserBlacklisted ? Color.gray :
                    (locationManager.location != nil && diamondManager.hasEnoughDiamonds(1) ? Color.blue : Color.gray)
                )
                .cornerRadius(10)
            }
            .disabled(isLoading || locationManager.location == nil || isUserBlacklisted)
            .onAppear {
                print("🔍 寻找按钮状态调试:")
                print("   isLoading: \(isLoading)")
                print("   locationManager.location: \(locationManager.location != nil)")
                print("   isUserBlacklisted: \(isUserBlacklisted)")
                print("   按钮是否禁用: \(isLoading || locationManager.location == nil || isUserBlacklisted)")
                
                // 主动请求位置信息
                if locationManager.location == nil {
                    print("📍 主动请求位置信息...")
                    locationManager.requestLocation()
                }
            }
            .padding(.top, 20)
            
            // 位置状态提示
            if locationManager.location == nil && !isLoading && !isUserBlacklisted {
                HStack {
                    Image(systemName: "location.slash")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("正在获取位置信息...")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
            
            // 倒计时显示
            if isUserBlacklisted && !timeRemaining.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    Text("剩余时间: \(timeRemaining)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
            
            // 邮箱和用户信息
            if let record = randomRecord {
                VStack(spacing: 15) {
                    // 用户头像和用户名信息 - 最重要的信息，使用大字体
                    HStack(spacing: 12) {
                        // 显示用户头像
                        if let userAvatar = record.user_avatar, !userAvatar.isEmpty {
                            if userAvatar == "apple_logo" {
                                // 显示Apple logo SF Symbol
                                Image(systemName: "applelogo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.black)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                    )
                            } else {
                                // 显示其他emoji头像
                                Text(userAvatar)
                                    .font(.system(size: 32))
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                    )
                            }
                        } else {
                            // 如果没有头像，根据用户类型显示默认头像
                            if record.login_type == "apple" {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.black)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                    )
                            } else if record.login_type == "internal" {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.purple)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                    )
                            } else {
                                Text("👥")
                                    .font(.system(size: 32))
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                    )
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            // 用户名
                            Text(record.user_name ?? "未知用户")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .onLongPressGesture {
                                    UIPasteboard.general.string = record.user_name ?? "未知用户"
                                    copySuccessMessage = "用户名已复制"
                                    showCopySuccess = true
                                    // 2秒后自动隐藏提示
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showCopySuccess = false
                                    }
                                }
                            
                            // 用户类型标识
                            HStack(spacing: 4) {
                                if record.login_type == "apple" {
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.black)
                                        .font(.system(size: 14))
                                    Text("Apple用户")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("👥")
                                        .font(.system(size: 14))
                                    Text("游客用户")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    // 邮箱信息 - 次要信息，使用中等字体
                    if let userEmail = record.user_email, !userEmail.isEmpty {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                            Text(userEmail)
                                .font(.body)
                                .foregroundColor(.blue)
                                .onLongPressGesture {
                                    UIPasteboard.general.string = userEmail
                                    copySuccessMessage = "邮箱已复制"
                                    showCopySuccess = true
                                    // 2秒后自动隐藏提示
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showCopySuccess = false
                                    }
                                }
                        }
                    }
                }
                .padding(.top, 20)
            }
            
            // 显示距离标签
            if let record = randomRecord, let currentLocation = locationManager.location {
                let distance = calculateDistance(from: currentLocation, to: record.latitude, targetLongitude: record.longitude)
                Text(formatDistance(distance))
                    .font(.body)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                    .padding(.top, 10)
            } else {
                Text("--")
                    .font(.body)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                    .padding(.top, 10)
            }
            
            // 显示时间标签和精度
            if let record = randomRecord {
                VStack(spacing: 4) {
                    Text(formatTimestamp(record.timestamp, tzID: record.timezone))
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    
                    // 显示时区信息和精度
                    HStack(spacing: 8) {
                        // 显示时区信息
                        if shouldShowTimezone(record.longitude) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                Text(calculateTimezoneFromLongitude(record.longitude))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("(\(getTimezoneName(record.longitude)))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // 显示精度信息
                        HStack(spacing: 4) {
                            Image(systemName: "location.circle")
                                .foregroundColor(.purple)
                                .font(.system(size: 12))
                            Text("精度: \(String(format: "%.1f", record.accuracy))m")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding(.top, 5)
            } else {
                Text("--")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
                    .padding(.top, 5)
            }
            
            if isLoadingRandomRecord {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                                            Text("🎯 寻找随机记录中...")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                .padding(.top, 10)
            }
            
            if !resultMessage.isEmpty {
                Text(resultMessage)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .foregroundColor(.green)
            }
            
            // 复制成功提示
            if showCopySuccess {
                Text(copySuccessMessage)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: showCopySuccess)
            }
        }
        .padding()
        .alert("提示", isPresented: $showAlert) {
            Button("确定") { }
        } message: {
            Text(resultMessage)
        }
        .alert("确认退出", isPresented: $showLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                userManager.logout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .alert("自定义昵称", isPresented: $showEditNameAlert) {
            TextField("输入新昵称", text: $newUserName)
            Button("取消", role: .cancel) {
                newUserName = ""
            }
            Button("确定") {
                if !newUserName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    userManager.updateUserName(newUserName.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                newUserName = ""
            }
        } message: {
            Text("请输入您喜欢的昵称")
        }
        .alert("更改邮箱", isPresented: $showEditEmailAlert) {
            Button("去设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl) { success in
                        if success {
                        } else {
                        }
                    }
                } else {
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("邮箱地址由 Apple ID 管理，请在系统设置中更改您的 Apple ID 邮箱地址\n1. 点击'Apple ID'\n2. 选择'登录与安全性'\n3. 修改邮箱地址")
        }
        .alert("账户删除提醒", isPresented: $showCancelDeletionAlert) {
            Button("取消删除", role: .cancel) {
                cancelAccountDeletion()
            }
            Button("继续删除", role: .destructive) {
                // 继续删除，立即退出登录
                userManager.clearAppleIDStoredInfo()
                // 清除历史记录
                clearAllHistory()
                userManager.logout()
            }
        } message: {
            Text("检测到您的账户有删除请求，预计删除时间：\(pendingDeletionDate)\n\n是否要取消删除请求？")
        }
        .onAppear {
            // 连接钻石管理器与用户管理器
            userManager.diamondManager = diamondManager
            
            // 如果用户已经登录但钻石管理器还没有设置用户信息，重新设置
            if let currentUser = userManager.currentUser {
                let loginType: String
                switch currentUser.loginType {
                case .apple:
                    loginType = "apple"
                case .guest:
                    loginType = "guest"
                case .internal:
                    loginType = "internal"
                }
                diamondManager.setCurrentUser(userId: currentUser.id, loginType: loginType, userName: currentUser.fullName, userEmail: currentUser.email)
            }
            
            // 进入页面时再次请求位置
            locationManager.requestLocation()
            // 启动方向更新
            locationManager.startHeadingUpdates()
            // 加载黑名单
            loadBlacklist()
            // 加载举报记录
            loadReportRecords()
            // 加载随机匹配历史记录
            loadRandomMatchHistory()
            
            // 检查是否有待删除的账户请求
            checkPendingDeletionRequest()
        }
        .onDisappear {
            // 离开页面时停止方向更新
            locationManager.stopHeadingUpdates()
            // 停止倒计时定时器
            stopCountdownTimer()
        }
        .sheet(isPresented: $showLocationHistory) {
            LocationHistoryView(locations: locationHistory, isLoading: false)
        }
        .sheet(isPresented: $showRandomHistory) {
            RandomMatchHistoryView(
                history: randomMatchHistory,
                calculateDistance: calculateDistance,
                formatDistance: formatDistance,
                formatTimestamp: formatTimestamp,
                calculateBearing: calculateBearing,
                getDirectionText: getDirectionText,
                calculateTimezoneFromLongitude: calculateTimezoneFromLongitude,
                getTimezoneName: getTimezoneName,
                onClearHistory: clearRandomMatchHistory,
                onDeleteHistoryItem: deleteRandomMatchHistoryItem,
                onReportUser: { userId, userName, userEmail, reason, deviceId, loginType in
                    addReportRecord(reportedUserId: userId, reportedUserName: userName, reportedUserEmail: userEmail, reportReason: reason, reportedDeviceId: deviceId, reportedUserLoginType: loginType)
                },
                hasReportedUser: hasReportedUser
            )
        }
        .sheet(isPresented: $showRechargeSheet) {
            RechargeView(diamondManager: diamondManager)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileView(
                userManager: userManager,
                diamondManager: diamondManager,
                showEditEmailAlert: $showEditEmailAlert,
                showLogoutAlert: $showLogoutAlert,
                showRechargeSheet: $showRechargeSheet,
                newUserName: $newUserName,
                isUserBlacklisted: isUserBlacklisted,
                onClearAllHistory: clearAllHistory
            )
        }
        .sheet(isPresented: $showAvatarZoom) {
            AvatarZoomView(userManager: userManager, showRandomButton: false)
        }
        .navigationBarBackButtonHidden(false)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 应用重新激活时检查是否需要更新 Apple ID 信息
            userManager.checkAndUpdateAppleIDInfo()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 应用重新激活时检查是否需要更新 Apple ID 信息
            userManager.checkAndUpdateAppleIDInfo()
        }
                        .interactiveDismissDisabled(false)
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // 应用重新激活时检查是否需要更新 Apple ID 信息
                            userManager.checkAndUpdateAppleIDInfo()
                        }
    }
    
    // 检查是否有待删除的账户请求
    func checkPendingDeletionRequest() {
        guard let currentUser = userManager.currentUser else {
            return
        }
        
        LeanCloudService.shared.checkPendingDeletionRequest(userId: currentUser.id) { hasPendingDeletion, deletionDate in
            DispatchQueue.main.async {
                if hasPendingDeletion {
                    // 格式化删除日期显示
                    if let deletionDate = deletionDate {
                        let formatter = ISO8601DateFormatter()
                        if let date = formatter.date(from: deletionDate) {
                            let displayFormatter = DateFormatter()
                            displayFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
                            displayFormatter.timeZone = TimeZone.current
                            self.pendingDeletionDate = displayFormatter.string(from: date)
                        } else {
                            self.pendingDeletionDate = "7天后"
                        }
                    } else {
                        self.pendingDeletionDate = "7天后"
                    }
                    
                    // 显示取消删除确认对话框
                    self.showCancelDeletionAlert = true
                }
            }
        }
    }
    
    // 取消账户删除请求
    func cancelAccountDeletion() {
        guard let currentUser = userManager.currentUser else {
            return
        }
        
        LeanCloudService.shared.cancelAccountDeletion(userId: currentUser.id) { success in
            DispatchQueue.main.async {
                if success {
                    // 可以显示成功提示
                } else {
                    // 可以显示错误提示
                }
            }
        }
    }
    
    // 清除所有历史记录
    func clearAllHistory() {
        // 只清除当前用户类型的历史记录
        UserDefaults.standard.removeObject(forKey: getHistoryKey())
        // 清除位置历史记录
        UserDefaults.standard.removeObject(forKey: "locationHistory")
        // 清除举报记录
        UserDefaults.standard.removeObject(forKey: getReportRecordsKey())
        reportRecords.removeAll()
        // 清除黑名单记录
        UserDefaults.standard.removeObject(forKey: "blacklistedUserIds")
        
        // 已清除当前用户类型的本地历史记录
    }
    
    func sendLocationToServer() {
        // 检查钻石是否足够（但不立即扣除）
        guard diamondManager.hasEnoughDiamonds(1) else {
            showRechargeSheet = true
            return
        }
        
        isLoading = true
        resultMessage = ""
        
        
        // 先刷新黑名单，然后开始寻找流程
        refreshBlacklistAndHistory()
        
        
        // 首先请求更新位置信息
        locationManager.requestLocation()
        
        // 等待位置更新完成后再发送
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let location = self.locationManager.location else {
                self.isLoading = false
                self.resultMessage = "无法获取位置信息，请重试"
                self.showAlert = true
                return
            }
            
            
            // 获取设备标识符
            let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
            
            // 准备要发送的数据
            let userId = self.userManager.currentUser?.id ?? "unknown_user"
            let userName = self.userManager.currentUser?.fullName ?? "未知用户"
            let loginType: String
            switch self.userManager.currentUser?.loginType {
            case .apple:
                loginType = "apple"
            case .internal:
                loginType = "internal"
            case .guest:
                loginType = "guest"
            default:
                loginType = "guest"
            }
            let userEmail = self.userManager.currentUser?.email
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                let tzID = placemarks?.first?.timeZone?.identifier ?? TimeZone.current.identifier

                // 判断是否在中国境内


                // 生成设备时间字符串 - 使用ISO 8601 UTC格式
                let localDate = Date()
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let deviceTime = isoFormatter.string(from: localDate)

                // 获取用户头像信息 - 基于用户类型设置默认头像
                let userAvatar: String
                switch loginType {
                case "apple":
                    userAvatar = "apple_logo" // Apple logo SF Symbol
                case "internal":
                    userAvatar = "👤" // 内部用户 emoji
                case "guest":
                    userAvatar = "👥" // 游客 emoji
                default:
                    userAvatar = "👤" // 默认 emoji
                }
                
                let locationData: [String: Any] = [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                    "accuracy": location.horizontalAccuracy, // 添加精度信息
                    "user_id": userId,
                    "user_name": userName,
                    "login_type": loginType,
                    "user_email": userEmail ?? "", // 添加邮箱字段
                    "user_avatar": userAvatar, // 添加用户头像
                    "device_id": deviceID,
                    "timezone": tzID,
                    "device_time": deviceTime  // 可能已转为北京时间
                ]


                LeanCloudService.shared.sendLocation(locationData: locationData) { success, message in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if success {
                            self.fetchRandomRecord()
                        } else {
                            // 提供更详细的错误信息
                            if message.contains("API密钥配置错误") {
                                self.resultMessage = "API配置错误：\n请检查LeanCloud配置\n\n错误详情：\(message)\n\n建议：\n1. 检查App ID和App Key是否正确\n2. 确认Server URL格式\n3. 点击'API配置检查'按钮进行诊断"
                            } else {
                                self.resultMessage = message
                            }
                            self.showAlert = true
                        }
                    }
                }
            }
        }
    }
    

    

    

    
    func formatTimestamp(_ timestamp: String, tzID: String?) -> String {
        // 尝试多种时间格式解析
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: timestamp) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "yyyy-M-d HH:mm"
                displayFormatter.locale = Locale(identifier: "zh_CN")
                displayFormatter.timeZone = nil
                return displayFormatter.string(from: date)
            }
        }
        
        // 如果所有格式都解析失败，返回原始时间戳
        return timestamp
    }
    
    // 格式化时间为"多少分钟之前"的格式
    func formatTimeAgo(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if minutes < 1 {
            return "刚刚"
        } else if minutes < 60 {
            return "\(minutes)分钟前"
        } else if hours < 24 {
            return "\(hours)小时前"
        } else if days < 30 {
            return "\(days)天前"
        } else {
            // 超过30天显示具体日期
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MM-dd HH:mm"
            displayFormatter.locale = Locale(identifier: "zh_CN")
            displayFormatter.timeZone = nil
            return displayFormatter.string(from: date)
        }
    }
    
    // 计算两个地理坐标之间的直线距离（使用Haversine公式）
    func calculateDistance(from currentLocation: CLLocation, to targetLatitude: Double, targetLongitude: Double) -> Double {
        let targetLocation = CLLocation(latitude: targetLatitude, longitude: targetLongitude)
        return currentLocation.distance(from: targetLocation) // 返回米为单位的距离
    }
    
    // 计算从当前位置到目标位置的方向角度（以正北方向为0度）
    func calculateBearing(from currentLocation: CLLocation, to targetLatitude: Double, targetLongitude: Double) -> Double {
        let lat1 = currentLocation.coordinate.latitude * .pi / 180
        let lat2 = targetLatitude * .pi / 180
        let deltaLon = (targetLongitude - currentLocation.coordinate.longitude) * .pi / 180
        
        let x = sin(deltaLon) * cos(lat2)
        let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        
        let bearingRadians = atan2(x, y)
        let bearingDegrees = bearingRadians * 180 / .pi
        
        // 确保角度在0-360度范围内
        return bearingDegrees >= 0 ? bearingDegrees : bearingDegrees + 360
    }
    
    // 根据经度计算时区
    func calculateTimezoneFromLongitude(_ longitude: Double) -> String {
        // 每15度经度对应1小时时差
        let timezoneOffset = Int(round(longitude / 15.0))
        
        // 限制在-12到+14的范围内
        let clampedOffset = max(-12, min(14, timezoneOffset))
        
        // 格式化时区显示
        if clampedOffset >= 0 {
            return "UTC+\(clampedOffset)"
        } else {
            return "UTC\(clampedOffset)"
        }
    }
    
    // 判断是否应该显示时区信息（UTC+8不显示）
    func shouldShowTimezone(_ longitude: Double) -> Bool {
        let timezoneOffset = Int(round(longitude / 15.0))
        let clampedOffset = max(-12, min(14, timezoneOffset))
        return clampedOffset != 8 // UTC+8时不显示时区信息
    }
    
    // 获取时区名称（基于经度的简化版本）
    func getTimezoneName(_ longitude: Double) -> String {
        let timezoneOffset = Int(round(longitude / 15.0))
        let clampedOffset = max(-12, min(14, timezoneOffset))
        
        // 根据经度范围返回主要时区名称
        switch clampedOffset {
        case -12...(-8):
            return "太平洋时间"
        case -7...(-5):
            return "北美中部时间"
        case -4...(-2):
            return "大西洋时间"
        case -1...1:
            return "格林威治时间"
        case 2...4:
            return "欧洲中部时间"
        case 5...7:
            return "亚洲中部时间"
        case 8:
            return "中国北京时间"
        case 9:
            return "日本标准时间"
        case 10...11:
            return "澳大利亚东部时间"
        case 12...14:
            return "新西兰标准时间"
        default:
            return "未知时区"
        }
    }
    
    // 根据角度返回方向文字描述
    func getDirectionText(_ bearing: Double) -> String {
        switch bearing {
        case 0..<22.5, 337.5...360:
            return "正北"
        case 22.5..<67.5:
            return "东北"
        case 67.5..<112.5:
            return "正东"
        case 112.5..<157.5:
            return "东南"
        case 157.5..<202.5:
            return "正南"
        case 202.5..<247.5:
            return "西南"
        case 247.5..<292.5:
            return "正西"
        case 292.5..<337.5:
            return "西北"
        default:
            return "未知"
        }
    }
    
    // 格式化距离显示 - 精确到厘米
    func formatDistance(_ distanceInMeters: Double) -> String {
        let distanceInCentimeters = distanceInMeters * 100
        
        if distanceInMeters < 1 {
            // 小于1米时，显示厘米
            return String(format: "%.0fcm", distanceInCentimeters)
        } else if distanceInMeters < 1000 {
            // 1米到1000米之间，显示米和厘米
            let meters = Int(distanceInMeters)
            let centimeters = Int(distanceInCentimeters.truncatingRemainder(dividingBy: 100))
            return "\(meters)m\(centimeters)cm"
        } else {
            // 大于1000米时，显示千米和米和厘米
            let kilometers = Int(distanceInMeters / 1000)
            let remainingMeters = distanceInMeters.truncatingRemainder(dividingBy: 1000)
            let meters = Int(remainingMeters)
            let centimeters = Int(distanceInCentimeters.truncatingRemainder(dividingBy: 100))
            return "\(kilometers)km\(meters)m\(centimeters)cm"
        }
    }
    
    func fetchRandomRecord() {
        isLoadingRandomRecord = true
        randomRecord = nil // 清除之前的记录
        randomRecordNumber = 0 // 重置序号
        
        // 重新加载历史记录以确保数据是最新的
        loadRandomMatchHistory()
        
        
        // 先获取所有记录以确定总数
        LeanCloudService.shared.fetchLocations { records, error in
            DispatchQueue.main.async {
                if let _ = error {
                    self.isLoadingRandomRecord = false
                    return
                }
                
                let totalRecords = records?.count ?? 0
                
                // 使用LeanCloud服务获取随机位置记录
                let currentLocation = self.locationManager.location?.coordinate
                // 获取当前用户ID
                let currentUserId = self.userManager.currentUser?.id
                // 从历史记录中提取位置记录用于排除
                let historyRecords = self.randomMatchHistory.map { $0.record }
                for _ in historyRecords.enumerated() {
                }
                LeanCloudService.shared.fetchRandomLocation(currentLocation: currentLocation, currentUserId: currentUserId, excludeHistory: historyRecords) { record, error in
                    DispatchQueue.main.async {
                        self.isLoadingRandomRecord = false
                        
                        if let _ = error {
                            // 匹配失败，不扣除钻石
                        } else if let record = record {
                            // 成功匹配到用户，扣除钻石
                            if self.diamondManager.spendDiamonds(1) {
                                // 钻石扣除成功
                            } else {
                                // 钻石扣除失败
                            }
                            
                            self.randomRecord = record
                            // 为随机记录分配一个序号（1到总数之间）
                            self.randomRecordNumber = Int.random(in: 1...max(1, totalRecords))
                            
                            // 输出匹配对象的全部信息
                            
                            // 添加到随机匹配历史
                            self.addRandomMatchToHistory(record: record, recordNumber: self.randomRecordNumber)
                        } else {
                            // 没有匹配到用户，不扣除钻石
                        }
                    }
                }
            }
        }
    }
    

    
    // 获取历史记录键名（根据登录类型和用户ID）
    func getHistoryKey() -> String {
        guard let currentUser = userManager.currentUser else {
            return "randomMatchHistory_guest" // 默认使用游客键名
        }
        
        // 根据登录类型和用户ID生成唯一的键名
        switch currentUser.loginType {
        case .apple:
            // Apple ID登录：使用邮箱作为唯一标识
            let email = currentUser.email ?? "unknown"
            return "randomMatchHistory_apple_\(email)"
        case .internal:
            // 内部账号登录：使用用户ID作为唯一标识
            return "randomMatchHistory_internal_\(currentUser.id)"
        case .guest:
            // 游客登录：使用设备ID作为唯一标识
            let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
            let shortDeviceID = String(deviceID.prefix(8))
            return "randomMatchHistory_guest_\(shortDeviceID)"
        }
    }
    
    // 获取举报记录键名（根据登录类型和用户ID）
    func getReportRecordsKey() -> String {
        guard let currentUser = userManager.currentUser else {
            return "reportRecords_guest"
        }
        switch currentUser.loginType {
        case .apple:
            let email = currentUser.email ?? "unknown"
            return "reportRecords_apple_\(email)"
        case .internal:
            return "reportRecords_internal_\(currentUser.id)"
        case .guest:
            let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
            let shortDeviceID = String(deviceID.prefix(8))
            return "reportRecords_guest_\(shortDeviceID)"
        }
    }
    
    // 保存随机匹配历史到本地
    func saveRandomMatchHistory() {
        if let data = try? JSONEncoder().encode(randomMatchHistory) {
            UserDefaults.standard.set(data, forKey: getHistoryKey())
        }
    }
    
    // 从本地加载随机匹配历史
    func loadRandomMatchHistory() {
        // 先清空当前历史记录数组，确保不会显示上一个账号的历史
        randomMatchHistory.removeAll()
        
        let historyKey = getHistoryKey()
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([RandomMatchHistory].self, from: data) {
            // 过滤掉黑名单用户和设备的记录
            let filteredHistory = history.filter { historyItem in
                !blacklistedUserIds.contains(historyItem.record.user_name ?? "") && 
                !blacklistedUserIds.contains(historyItem.record.device_id)
            }
            
            randomMatchHistory = filteredHistory
            
            // 如果过滤后有变化，保存过滤后的历史记录
            if filteredHistory.count != history.count {
                saveRandomMatchHistory()
            }
            
            for (_, historyItem) in filteredHistory.enumerated() {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                _ = formatter.string(from: historyItem.matchTime)
            }
        } else {
            // 如果没有找到历史记录，确保数组为空
            randomMatchHistory = []
        }
    }
    
    // 添加新的随机匹配记录
    func addRandomMatchToHistory(record: LocationRecord, recordNumber: Int) {
        // 检查是否在黑名单中（检查用户名或设备ID）
        if blacklistedUserIds.contains(record.user_name ?? "") || blacklistedUserIds.contains(record.device_id) {
            return
        }
        
        let currentLocation = locationManager.location?.coordinate
        let newHistory = RandomMatchHistory(record: record, recordNumber: recordNumber, currentLocation: currentLocation)
        randomMatchHistory.insert(newHistory, at: 0) // 插入到开头
        
        // 限制历史记录数量，最多保存50条
        if randomMatchHistory.count > 50 {
            randomMatchHistory = Array(randomMatchHistory.prefix(50))
        }
        
        saveRandomMatchHistory()
    }
    
    // 清除随机匹配历史
    func clearRandomMatchHistory() {
        randomMatchHistory.removeAll()
        // 只清除当前用户类型的历史记录
        UserDefaults.standard.removeObject(forKey: getHistoryKey())
        // 清除举报记录
        UserDefaults.standard.removeObject(forKey: getReportRecordsKey())
        reportRecords.removeAll()
    }
    

    
    // 删除单个随机匹配历史记录
    func deleteRandomMatchHistoryItem(_ historyItem: RandomMatchHistory) {
        if let index = randomMatchHistory.firstIndex(where: { $0.id == historyItem.id }) {
            randomMatchHistory.remove(at: index)
            saveRandomMatchHistory()
        }
    }
    
    // 保存举报记录到本地
    func saveReportRecords() {
        if let data = try? JSONEncoder().encode(reportRecords) {
            UserDefaults.standard.set(data, forKey: getReportRecordsKey())
        }
    }
    
    // 从本地加载举报记录
    func loadReportRecords() {
        reportRecords.removeAll()
        if let data = UserDefaults.standard.data(forKey: getReportRecordsKey()),
           let records = try? JSONDecoder().decode([ReportRecord].self, from: data) {
            reportRecords = records
        }
    }
    
    // 添加举报记录
    func addReportRecord(reportedUserId: String, reportedUserName: String?, reportedUserEmail: String?, reportReason: String, reportedDeviceId: String? = nil, reportedUserLoginType: String? = nil) {
        print("📋 开始添加举报记录...")
        print("   📄 被举报用户ID: \(reportedUserId)")
        print("   📄 被举报用户姓名: \(reportedUserName ?? "未知")")
        print("   📄 被举报用户邮箱: \(reportedUserEmail ?? "未知")")
        print("   📄 被举报用户设备ID: \(reportedDeviceId ?? "未知")")
        print("   📄 被举报用户类型: \(reportedUserLoginType ?? "未知")")
        print("   📄 举报原因: \(reportReason)")
        
        guard let currentUser = userManager.currentUser else {
            print("   ❌ 当前用户未登录")
            return
        }
        
        let newReport = ReportRecord(
            reportedUserId: reportedUserId,
            reportedUserName: reportedUserName,
            reportedUserEmail: reportedUserEmail,
            reportReason: reportReason,
            reporterUserId: currentUser.id,
            reporterUserName: currentUser.fullName
        )
        
        // 保存到本地
        reportRecords.append(newReport)
        saveReportRecords()
        
        // 获取举报者头像信息 - 基于用户类型设置默认头像
        let reporterAvatar: String
        switch currentUser.loginType {
        case .apple:
            reporterAvatar = "apple_logo" // Apple logo SF Symbol
        case .internal:
            reporterAvatar = "👤" // 内部用户 emoji
        case .guest:
            reporterAvatar = "👥" // 游客 emoji
        default:
            reporterAvatar = "👤" // 默认 emoji
        }
        
        // 获取被举报者头像信息（使用默认头像，因为无法获取被举报者的真实头像）
        let reportedUserAvatar = "👤" // 被举报者默认头像
        
        // 尝试上传到LeanCloud - 包含用户类型字段
        var reportData: [String: Any] = [
            "reported_user_id": reportedDeviceId ?? "unknown_device", // 被举报者的设备ID
            "reported_user_name": reportedUserName ?? "",
            "reported_user_email": reportedUserEmail ?? "",
            "reported_user_login_type": reportedUserLoginType ?? "unknown", // 被举报者的用户类型
            "reported_user_avatar": reportedUserAvatar, // 添加被举报者头像
            "report_reason": reportReason,
            "report_time": ISO8601DateFormatter().string(from: Date()),
            "reporter_user_id": currentUser.id,
            "reporter_user_name": currentUser.fullName,
            "reporter_user_avatar": reporterAvatar // 添加举报者头像
        ]
        
        // 如果上传失败，尝试不包含用户类型字段的版本
        let fallbackReportData: [String: Any] = [
            "reported_user_id": reportedDeviceId ?? "unknown_device",
            "reported_user_name": reportedUserName ?? "",
            "reported_user_email": reportedUserEmail ?? "",
            "reported_user_avatar": reportedUserAvatar, // 添加被举报者头像
            "report_reason": reportReason,
            "report_time": ISO8601DateFormatter().string(from: Date()),
            "reporter_user_id": currentUser.id,
            "reporter_user_name": currentUser.fullName,
            "reporter_user_avatar": reporterAvatar // 添加举报者头像
        ]
        
        print("📋 构建举报数据...")
        print("   📄 reported_user_login_type: \(reportedUserLoginType ?? "unknown")")
        print("   📄 完整举报数据: \(reportData)")
        
        print("📋 开始上传举报记录...")
        print("   📄 举报数据: \(reportData)")
        print("   📝 已包含 reported_user_login_type 字段")
        do {
            let dataSize = try JSONSerialization.data(withJSONObject: reportData).count
            print("   📊 数据大小: \(dataSize) bytes")
        } catch {
            print("   ⚠️ 无法计算数据大小: \(error.localizedDescription)")
        }
        
        LeanCloudService.shared.uploadReportRecord(reportData: reportData) { success, message in
            if success {
                print("✅ 举报记录上传成功")
            } else {
                print("❌ 举报记录上传失败: \(message)")
                print("📋 失败详情:")
                print("   📄 举报数据: \(reportData)")
                do {
                    let dataSize = try JSONSerialization.data(withJSONObject: reportData).count
                    print("   📊 数据大小: \(dataSize) bytes")
                } catch {
                    print("   ⚠️ 无法计算数据大小: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 检查是否已举报过该用户
    func hasReportedUser(_ userId: String) -> Bool {
        return reportRecords.contains { $0.reportedUserId == userId }
    }
    
    // 加载黑名单用户ID和设备ID列表
    func loadBlacklist() {
        // 获取设备ID
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        
        LeanCloudService.shared.fetchBlacklist { blacklistedIds, error in
            DispatchQueue.main.async {
                if let _ = error {
                    return
                }
                
                if let blacklistedIds = blacklistedIds {
                    self.blacklistedUserIds = blacklistedIds
                    
                    // 检查当前用户是否在黑名单中（检查用户名或设备ID）
                    if let currentUserName = self.userManager.currentUser?.fullName {
                        let userIsBlacklisted = blacklistedIds.contains(currentUserName) || blacklistedIds.contains(deviceID)
                        
                        // 添加调试信息
                        print("🔍 黑名单检查调试信息:")
                        print("   当前用户名: \(currentUserName)")
                        print("   当前设备ID: \(deviceID)")
                        print("   黑名单列表: \(blacklistedIds)")
                        print("   用户名在黑名单中: \(blacklistedIds.contains(currentUserName))")
                        print("   设备ID在黑名单中: \(blacklistedIds.contains(deviceID))")
                        print("   用户是否被禁用: \(userIsBlacklisted)")
                        
                        self.isUserBlacklisted = userIsBlacklisted
                        if userIsBlacklisted {
                            // 获取用户的过期时间（优先检查用户名，如果没有则检查设备ID）
                            if blacklistedIds.contains(currentUserName) {
                                print("   📋 用户名在黑名单中，获取用户过期时间")
                                self.getUserBlacklistExpiryTime(userId: currentUserName)
                            } else {
                                print("   📋 设备ID在黑名单中，获取设备过期时间")
                                self.getDeviceBlacklistExpiryTime(deviceId: deviceID)
                            }
                        } else {
                            print("   ✅ 用户未被禁用")
                            self.stopCountdownTimer()
                            self.blacklistExpiryTime = nil
                            self.timeRemaining = ""
                        }
                    }
                    
                    // 重新加载历史记录以应用黑名单过滤
                    self.loadRandomMatchHistory()
                } else {
                    self.blacklistedUserIds = []
                    self.isUserBlacklisted = false
                }
            }
        }
    }
    
    // 刷新黑名单和历史记录
    func refreshBlacklistAndHistory() {
        loadBlacklist()
    }
    
    // 获取用户/设备的黑名单过期时间
    func getUserBlacklistExpiryTime(userId: String) {
        print("🕐 开始获取用户黑名单过期时间: \(userId)")
        LeanCloudService.shared.fetchUserBlacklistExpiryTime(userId: userId) { expiryTime, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 获取用户黑名单过期时间失败: \(error)")
                    return
                }
                
                if let expiryTime = expiryTime {
                    print("✅ 获取到用户黑名单过期时间: \(expiryTime)")
                    self.blacklistExpiryTime = expiryTime
                    self.startCountdownTimer()
                } else {
                    print("⚠️ 用户黑名单过期时间为空")
                }
            }
        }
    }
    
    // 获取设备的黑名单过期时间
    func getDeviceBlacklistExpiryTime(deviceId: String) {
        print("🕐 开始获取设备黑名单过期时间: \(deviceId)")
        LeanCloudService.shared.fetchDeviceBlacklistExpiryTime(deviceId: deviceId) { expiryTime, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 获取设备黑名单过期时间失败: \(error)")
                    return
                }
                
                if let expiryTime = expiryTime {
                    print("✅ 获取到设备黑名单过期时间: \(expiryTime)")
                    self.blacklistExpiryTime = expiryTime
                    self.startCountdownTimer()
                } else {
                    print("⚠️ 设备黑名单过期时间为空")
                }
            }
        }
    }
    
    // 开始倒计时定时器
    func startCountdownTimer() {
        stopCountdownTimer() // 先停止之前的定时器
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateCountdown()
        }
    }
    
    // 停止倒计时定时器
    func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    // 更新倒计时显示
    func updateCountdown() {
        guard let expiryTime = blacklistExpiryTime else {
            timeRemaining = ""
            return
        }
        
        let now = Date()
        let timeInterval = expiryTime.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            // 已过期，停止定时器并刷新黑名单
            timeRemaining = ""
            stopCountdownTimer()
            blacklistExpiryTime = nil
            isUserBlacklisted = false
            refreshBlacklistAndHistory()
        } else {
            // 计算剩余时间
            let days = Int(timeInterval) / 86400
            let hours = Int(timeInterval) % 86400 / 3600
            let minutes = Int(timeInterval) % 3600 / 60
            let seconds = Int(timeInterval) % 60
            
            if days > 0 {
                timeRemaining = "\(days)天\(hours)小时\(minutes)分钟\(seconds)秒"
            } else if hours > 0 {
                timeRemaining = "\(hours)小时\(minutes)分钟\(seconds)秒"
            } else if minutes > 0 {
                timeRemaining = "\(minutes)分钟\(seconds)秒"
            } else {
                timeRemaining = "\(seconds)秒"
            }
        }
    }
}

// 位置历史记录视图
struct LocationHistoryView: View {
    let locations: [LocationRecord]
    let isLoading: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("加载中...")
                            .padding()
                    }
                } else if locations.isEmpty {
                    VStack {
                        Image(systemName: "location.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无位置记录")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("发送位置后这里会显示记录")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List(Array(locations.enumerated().reversed()), id: \.element.id) { index, location in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("记录 #\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(formatDate(location.timestamp, tzID: location.timezone))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("📍 纬度: \(String(format: "%.6f", location.latitude))")
                                        .font(.caption)
                                    Text("📍 经度: \(String(format: "%.6f", location.longitude))")
                                        .font(.caption)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("👤 \(location.user_name ?? "未知用户")")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("🔐 \(location.login_type ?? "guest")")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("📱 \(String(location.device_id.prefix(8)))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("位置记录 (\(locations.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String, tzID: String?) -> String {
        // 直接按本地时间解析，不做时区转换
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        localFormatter.timeZone = nil // 使用本地时区
        
        if let date = localFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .medium
            displayFormatter.locale = Locale(identifier: "zh_CN")
            displayFormatter.timeZone = nil // 直接显示本地时间
            return displayFormatter.string(from: date)
        }
        
        // 如果本地格式解析失败，尝试其他格式
        let otherFormatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                formatter.timeZone = nil
                return formatter
            }()
        ]
        
        for formatter in otherFormatters {
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .short
                displayFormatter.timeStyle = .medium
                displayFormatter.locale = Locale(identifier: "zh_CN")
                displayFormatter.timeZone = nil
                return displayFormatter.string(from: date)
            }
        }
        
        return dateString
    }

    func formatTimestamp(_ timestamp: String, tzID: String?) -> String {
        // 尝试多种时间格式解析
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: timestamp) {
                let now = Date()
                let timeInterval = now.timeIntervalSince(date)
                
                let minutes = Int(timeInterval / 60)
                let hours = Int(timeInterval / 3600)
                let days = Int(timeInterval / 86400)
                
                if minutes < 1 {
                    return "刚刚"
                } else if minutes < 60 {
                    return "\(minutes)分钟前"
                } else if hours < 24 {
                    return "\(hours)小时前"
                } else if days < 30 {
                    return "\(days)天前"
                } else {
                    // 超过30天显示具体日期
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "MM-dd HH:mm"
                    displayFormatter.locale = Locale(identifier: "zh_CN")
                    displayFormatter.timeZone = nil
                    return displayFormatter.string(from: date)
                }
            }
        }
        
        // 如果所有格式都解析失败，返回原始时间戳
        return timestamp
    }
}

// 指南针视图组件
struct CompassView: View {
    let bearing: Double
    @State private var animatedBearing: Double = 0
    @State private var compassScale: CGFloat = 0.8
    @State private var pulseOpacity: Double = 0.8
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let radius = size / 2
            
            ZStack {
                // 脉冲圆圈效果（缩小一点，避免被裁剪）
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    .scaleEffect(1.05)
                    .opacity(pulseOpacity)
                
                // 外圆背景
                Circle()
                    .stroke(Color.purple.opacity(0.4), lineWidth: 3)
                    .background(Circle().fill(Color.purple.opacity(0.05)))
                    .scaleEffect(compassScale)
                
                // 内圆刻度线
                ForEach(0..<36) { index in
                    let angle = Double(index) * 10
                    let isMainDirection = index % 9 == 0 // 每90度主方向
                    let isMidDirection = index % 3 == 0 // 每30度中等方向
                    
                    Rectangle()
                        .fill(Color.purple.opacity(isMainDirection ? 0.8 : (isMidDirection ? 0.6 : 0.3)))
                        .frame(
                            width: isMainDirection ? 2 : (isMidDirection ? 1.5 : 1),
                            height: isMainDirection ? size * 0.15 : (isMidDirection ? size * 0.1 : size * 0.06)
                        )
                        .offset(y: -(radius - (isMainDirection ? size * 0.075 : (isMidDirection ? size * 0.05 : size * 0.03))))
                        .rotationEffect(.degrees(angle))
                        .scaleEffect(compassScale)
                }
                

                

                
                // 中心点
                Circle()
                    .fill(Color.purple)
                    .frame(width: size * 0.08, height: size * 0.08)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .scaleEffect(compassScale)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            // 出现动画
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                compassScale = 1.0
            }
            
            // 脉冲动画
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.2
            }
            
            // 初始化角度
            animatedBearing = bearing
        }
        .onChange(of: bearing) { _, newBearing in
            // 平滑旋转动画
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8, blendDuration: 0)) {
                animatedBearing = newBearing
            }
        }
                        }
                }







// 随机记录显示组件
struct RandomRecordView: View {
    let record: LocationRecord
    let recordNumber: Int
    let currentLocation: CLLocation?
    let heading: CLHeading? // 新增
    let calculateDistance: (CLLocation, Double, Double) -> Double
    let formatDistance: (Double) -> String
    let formatTimestamp: (String, String?) -> String
    let calculateBearing: (CLLocation, Double, Double) -> Double
    let getDirectionText: (Double) -> String
    let calculateTimezoneFromLongitude: (Double) -> String
    let getTimezoneName: (Double) -> String
    
    // 新增：专用于随机发现的"多少分钟前"格式化
    func formatTimeAgoForRandomRecord(_ timestamp: String) -> String {
        // 尝试多种时间格式解析
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
                formatter.timeZone = nil
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: timestamp) {
                let now = Date()
                let timeInterval = now.timeIntervalSince(date)
                
                let minutes = Int(timeInterval / 60)
                let hours = Int(timeInterval / 3600)
                let days = Int(timeInterval / 86400)
                
                if minutes < 1 {
                    return "刚刚"
                } else if minutes < 60 {
                    return "\(minutes)分钟前"
                } else if hours < 24 {
                    return "\(hours)小时前"
                } else if days < 30 {
                    return "\(days)天前"
                } else {
                    // 超过30天显示具体日期
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateFormat = "MM-dd HH:mm"
                    displayFormatter.locale = Locale(identifier: "zh_CN")
                    displayFormatter.timeZone = nil
                    return displayFormatter.string(from: date)
                }
            }
        }
        
        // 如果所有格式都解析失败，返回原始时间戳
        return timestamp
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 显示与当前位置的距离和方向（导航信息）
            if let currentLocation = currentLocation {
                let distance = calculateDistance(
                    currentLocation,
                    record.latitude,
                    record.longitude
                )
                let bearing = calculateBearing(
                    currentLocation,
                    record.latitude,
                    record.longitude
                )
                let headingValue = heading?.trueHeading ?? 0 // 用真北
                let pointerAngle = (bearing - headingValue).truncatingRemainder(dividingBy: 360)
                // 保证角度为正
                let displayPointerAngle = pointerAngle < 0 ? pointerAngle + 360 : pointerAngle
                
                // 罗盘单独显示
                HStack {
                    Spacer()
                    CompassView(bearing: displayPointerAngle)
                        .frame(width: 80 * 3.17, height: 80 * 3.17)
                    Spacer()
                }
                
                // 所有信息放在罗盘下方
                VStack(alignment: .leading, spacing: 20) {
                    // 邮箱信息
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        if let userEmail = record.user_email, !userEmail.isEmpty {
                            Text(userEmail)
                                .font(.system(size: 12 * 2.26))
                                .foregroundColor(.blue)
                        } else {
                            Text("无")
                                .font(.system(size: 12 * 2.26))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    
                    // 用户名信息
                    HStack {
                        if record.login_type == "apple" {
                            Image(systemName: "applelogo")
                                .foregroundColor(.black)
                                .font(.system(size: 16))
                        } else {
                            Text("👥")
                        }
                        Text(record.user_name ?? "未知用户")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    // 显示距离
                    HStack {
                        Text("距离：\(formatDistance(distance))")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    // 显示时间
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("⏱️")
                            Text(formatTimeAgoForRandomRecord(record.timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                        
                        // 显示时区信息
                        HStack(spacing: 4) {
                            Image(systemName: "clock.badge")
                                .foregroundColor(.blue)
                                .font(.system(size: 8))
                            Text(calculateTimezoneFromLongitude(record.longitude))
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("(\(getTimezoneName(record.longitude)))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .padding(.bottom, 100)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
        .transition(.slide.combined(with: .opacity))
        .animation(.easeInOut(duration: 0.5), value: record.id)
    }
}

// 随机匹配历史视图
struct RandomMatchHistoryView: View {
    let history: [RandomMatchHistory]
    let calculateDistance: (CLLocation, Double, Double) -> Double
    let formatDistance: (Double) -> String
    let formatTimestamp: (String, String?) -> String
    let calculateBearing: (CLLocation, Double, Double) -> Double
    let getDirectionText: (Double) -> String
    let calculateTimezoneFromLongitude: (Double) -> String
    let getTimezoneName: (Double) -> String
    let onClearHistory: () -> Void
    let onDeleteHistoryItem: (RandomMatchHistory) -> Void
    let onReportUser: (String, String?, String?, String, String?, String?) -> Void
    let hasReportedUser: (String) -> Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var showClearAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("暂无随机匹配历史")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        Text("进行随机匹配后这里会显示历史")
                            .font(.body)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 60)
                } else {
                    List {
                        ForEach(history, id: \.id) { historyItem in
                            HistoryCardView(
                                historyItem: historyItem,
                                calculateDistance: calculateDistance,
                                formatDistance: formatDistance,
                                formatTimestamp: formatTimestamp,
                                calculateTimezoneFromLongitude: calculateTimezoneFromLongitude,
                                getTimezoneName: getTimezoneName,
                                onReportUser: { userId, userName, userEmail, reason, deviceId, loginType in
                    onReportUser(userId, userName, userEmail, reason, deviceId, loginType)
                },
                                hasReportedUser: hasReportedUser
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    // 删除单个历史记录
                                    deleteHistoryItem(historyItem)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("随机匹配历史")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !history.isEmpty {
                        Button("清除") {
                            showClearAlert = true
                        }
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .alert("确认清除", isPresented: $showClearAlert) {
                Button("取消", role: .cancel) { }
                Button("清除", role: .destructive) {
                    onClearHistory()
                }
            } message: {
                                        Text("确定要清除所有随机匹配历史吗？")
            }
        }
    }
    
    private func deleteHistoryItem(_ historyItem: RandomMatchHistory) {
        onDeleteHistoryItem(historyItem)
    }
    
    private func formatMatchTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// 举报弹窗视图
struct ReportSheetView: View {
    let userName: String
    let userEmail: String?
    let onReport: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason = "不当内容"
    @State private var customReason = ""
    @State private var showCustomReason = false
    
    // 举报原因字数限制
    private let maxCustomReasonLength = 50
    
    private let reportReasons = [
        "不当内容",
        "垃圾信息",
        "骚扰行为",
        "虚假信息",
        "其他"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Text("举报用户")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("您要举报的用户：\(userName)")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // 举报原因选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择举报原因")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        ForEach(reportReasons, id: \.self) { reason in
                            Button(action: {
                                selectedReason = reason
                                showCustomReason = (reason == "其他")
                            }) {
                                HStack {
                                    Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedReason == reason ? .blue : .gray)
                                        .font(.system(size: 16))
                                    
                                    Text(reason)
                                        .foregroundColor(.primary)
                                        .font(.body)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedReason == reason ? Color.blue.opacity(0.1) : Color.clear)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // 自定义原因输入
                if showCustomReason {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("请描述具体原因")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(customReason.count)/\(maxCustomReasonLength)")
                                .font(.caption)
                                .foregroundColor(customReason.count > maxCustomReasonLength ? .red : .gray)
                        }
                        
                        TextField("请输入举报原因...", text: $customReason, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .onChange(of: customReason) { _, newValue in
                                // 限制字数
                                if newValue.count > maxCustomReasonLength {
                                    customReason = String(newValue.prefix(maxCustomReasonLength))
                                }
                            }
                    }
                }
                
                Spacer()
                
                // 按钮区域
                VStack(spacing: 12) {
                    Button(action: {
                        let finalReason = showCustomReason && !customReason.isEmpty ? customReason : selectedReason
                        onReport(finalReason)
                    }) {
                        Text("确认举报")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .disabled(showCustomReason && (customReason.isEmpty || customReason.count > maxCustomReasonLength))
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("取消")
                            .font(.body)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .navigationTitle("举报用户")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 历史记录卡片视图
struct HistoryCardView: View {
    let historyItem: RandomMatchHistory
    let calculateDistance: (CLLocation, Double, Double) -> Double
    let formatDistance: (Double) -> String
    let formatTimestamp: (String, String?) -> String
    let calculateTimezoneFromLongitude: (Double) -> String
    let getTimezoneName: (Double) -> String
            let onReportUser: (String, String?, String?, String, String?, String?) -> Void
    let hasReportedUser: (String) -> Bool
    
    @State private var showReportSheet = false
    @State private var selectedReportReason = "不当内容"
    @State private var showCopySuccess = false // 新增：显示复制成功提示
    @State private var copySuccessMessage = "" // 新增：复制成功消息
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 卡片头部 - 匹配时间和类型
                            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                                            Text("随机匹配")
                                    .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                                Spacer()
                
                                Text(formatMatchTime(historyItem.matchTime))
                                    .font(.caption)
                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // 分隔线
            Divider()
                .background(Color.gray.opacity(0.2))
                .padding(.horizontal, 20)
            
            // 用户信息区域
            VStack(alignment: .leading, spacing: 16) {
                // 用户名和登录类型
                HStack(spacing: 12) {
                    // 用户头像
                    if let userAvatar = historyItem.record.user_avatar, !userAvatar.isEmpty {
                        if userAvatar == "apple_logo" {
                            // 显示Apple logo SF Symbol
                            Image(systemName: "applelogo")
                                .font(.system(size: 24))
                                .foregroundColor(.black)
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                )
                        } else {
                            // 显示其他emoji头像
                            Text(userAvatar)
                                .font(.system(size: 24))
                                .background(
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                )
                        }
                    } else {
                        // 如果没有头像，根据用户类型显示默认头像
                        ZStack {
                            Circle()
                                .fill(getUserTypeColor(historyItem.record.login_type))
                                .frame(width: 40, height: 40)
                            
                            if historyItem.record.login_type == "apple" {
                                Image(systemName: "applelogo")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .medium))
                            } else if historyItem.record.login_type == "internal" {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .medium))
                            } else {
                                Text("👥")
                                    .font(.system(size: 18))
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                                Text(historyItem.record.user_name ?? "未知用户")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .onLongPressGesture {
                                UIPasteboard.general.string = historyItem.record.user_name ?? "未知用户"
                                copySuccessMessage = "用户名已复制"
                                showCopySuccess = true
                                // 2秒后自动隐藏提示
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopySuccess = false
                                }
                            }
                        
                        Text(getUserTypeText(historyItem.record.login_type))
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(getUserTypeBackground(historyItem.record.login_type))
                            .cornerRadius(6)
                    }
                    
                    Spacer()
                    
                    // 举报按钮
                    if hasReportedUser(historyItem.record.user_id) {
                        // 已举报状态
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("已举报")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                    } else {
                        // 举报按钮
                        Button(action: {
                            showReportSheet = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))
                                Text("举报")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                            }
                            
                // 邮箱信息
                if let userEmail = historyItem.record.user_email, !userEmail.isEmpty {
                    HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                            .frame(width: 20)
                        
                                    Text(userEmail)
                            .font(.body)
                                        .foregroundColor(.blue)
                            .lineLimit(1)
                            .onLongPressGesture {
                                UIPasteboard.general.string = userEmail
                                copySuccessMessage = "邮箱已复制"
                                showCopySuccess = true
                                // 2秒后自动隐藏提示
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopySuccess = false
                                }
                            }
                        
                                Spacer()
                            }
                }
                
                                // 位置记录时间和精度
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatTimestamp(historyItem.record.timestamp, historyItem.record.timezone))
                            .font(.body)
                            .foregroundColor(.orange)
                        
                        // 显示时区信息和精度
                        HStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.badge")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 10))
                                Text(calculateTimezoneFromLongitude(historyItem.record.longitude))
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("(\(getTimezoneName(historyItem.record.longitude)))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            
                            // 精度信息
                            HStack(spacing: 4) {
                                Image(systemName: "location.circle")
                                    .foregroundColor(.purple)
                                    .font(.system(size: 10))
                                Text("精度: \(String(format: "%.1f", historyItem.record.accuracy))m")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
                            
            // 匹配时距离信息（如果有当前位置）
                            if let currentLocation = historyItem.currentLocation {
                                let distance = calculateDistance(
                                    CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude),
                                    historyItem.record.latitude,
                                    historyItem.record.longitude
                                )
                
                // 分隔线
                                    Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.horizontal, 20)
                
                // 距离信息
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 16))
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("随机匹配时距离")
                                        .font(.caption)
                            .foregroundColor(.gray)
                        Text(formatDistance(distance))
                            .font(.body)
                                        .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                                    
                                        Spacer()
                                    }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                }
            }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .overlay(
            // 复制成功提示
            VStack {
                if showCopySuccess {
                    Text(copySuccessMessage)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .cornerRadius(8)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showCopySuccess)
                }
                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 10)
            , alignment: .top
        )
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(
                userName: historyItem.record.user_name ?? "未知用户",
                userEmail: historyItem.record.user_email,
                onReport: { reason in
                                    onReportUser(
                    historyItem.record.user_id,
                    historyItem.record.user_name,
                    historyItem.record.user_email,
                    reason,
                    historyItem.record.device_id,
                    historyItem.record.login_type
                )
                    showReportSheet = false
                }
            )
        }
    }
    
    private func formatMatchTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    // 获取用户类型显示文本
    private func getUserTypeText(_ loginType: String?) -> String {
        switch loginType {
        case "apple":
            return "Apple ID用户"
        case "internal":
            return "内部用户"
        case "guest":
            return "游客用户"
        default:
            return "未知用户"
        }
    }
    
    // 获取用户类型背景颜色
    private func getUserTypeBackground(_ loginType: String?) -> Color {
        switch loginType {
        case "apple":
            return Color.black.opacity(0.1)
        case "internal":
            return Color.purple.opacity(0.1)
        case "guest":
            return Color.blue.opacity(0.1)
        default:
            return Color.gray.opacity(0.1)
        }
    }
    
    // 获取用户类型头像颜色
    private func getUserTypeColor(_ loginType: String?) -> Color {
        switch loginType {
        case "apple":
            return Color.black
        case "internal":
            return Color.purple
        case "guest":
            return Color.blue
        default:
            return Color.gray
        }
    }
}

    // 创建测试账号界面
struct CreateInternalAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("创建测试账号")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("请输入新账号信息")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // 创建表单
                VStack(spacing: 20) {
                    // 用户名输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("账号")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("请输入账号", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: username) { newValue in
                                // 只允许英文字母、数字和连字符
                                let filtered = newValue.filter { char in
                                    char.isLetter || char.isNumber || char == "-"
                                }
                                if filtered != newValue {
                                    username = filtered
                                }
                            }
                    }
                    
                    // 密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("密码")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("请输入密码", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: password) { newValue in
                                // 密码限制：只允许字母、数字和常用特殊字符，不允许空格
                                let filtered = newValue.filter { char in
                                    char.isLetter || char.isNumber || "!@#$%^&*()_+-=[]{}|;:,.<>?".contains(char)
                                }
                                if filtered != newValue {
                                    password = filtered
                                }
                            }
                    }
                    
                    // 确认密码输入
                    VStack(alignment: .leading, spacing: 8) {
                        Text("确认密码")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        SecureField("请再次输入密码", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: confirmPassword) { newValue in
                                // 密码限制：只允许字母、数字和常用特殊字符，不允许空格
                                let filtered = newValue.filter { char in
                                    char.isLetter || char.isNumber || "!@#$%^&*()_+-=[]{}|;:,.<>?".contains(char)
                                }
                                if filtered != newValue {
                                    confirmPassword = filtered
                                }
                            }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 创建按钮
                Button(action: {
                    createInternalAccount()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Text("创建账号")
                        }
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isFormValid() ? Color.purple : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid() || isLoading)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
            .navigationTitle("创建测试账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("创建结果", isPresented: $showAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // 检查表单是否有效
    private func isFormValid() -> Bool {
        return !username.isEmpty && 
               !password.isEmpty && 
               !confirmPassword.isEmpty && 
               password == confirmPassword &&
               password.count >= 6
    }
    
    // 创建测试账号
    private func createInternalAccount() {
        print("🔐 开始创建测试账号...")
        print("   📋 用户名: \(username)")
        print("   🔑 密码长度: \(password.count)")
        
        isLoading = true
        
        LeanCloudService.shared.createInternalAccount(username: username, password: password) { success, message in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    print("   ✅ 测试账号创建成功")
                    alertMessage = "🎉 测试账号创建成功！\n账号: \(username)"
                    showAlert = true
                    
                    // 清空表单
                    username = ""
                    password = ""
                    confirmPassword = ""
                    
                    // 延迟关闭界面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        dismiss()
                    }
                } else {
                    print("   ❌ 测试账号创建失败: \(message)")
                    alertMessage = "创建失败: \(message)"
                    showAlert = true
                }
            }
        }
    }
}

// 用户信息确认界面
struct UserInfoConfirmView: View {
    @ObservedObject var userManager: UserManager
    var onConfirm: () -> Void
    var onBack: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showEditNameAlert = false
    @State private var showEditEmailAlert = false
    @State private var agreedToTerms = false
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("用户信息确认")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            // 用户头像
            Image(systemName: "applelogo")
                .font(.system(size: 80))
                .foregroundColor(.black)
                .padding(.bottom, 20)
            
            // 用户信息卡片
            VStack(spacing: 20) {
                // 用户名
                VStack(alignment: .leading, spacing: 8) {
                    Text("用户名")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(userManager.currentUser?.fullName ?? "未知用户")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: {
                            // 用户名由 Apple ID 管理，提示用户去设置修改
                            showEditNameAlert = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    Text("该名称将用于与其他用户匹配时显示")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 邮箱
                VStack(alignment: .leading, spacing: 8) {
                    Text("邮箱地址（可选）")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        if let email = userManager.currentUser?.email {
                            Text(email)
                                .font(.title2)
                                .foregroundColor(.blue)
                        } else {
                            Text("未提供邮箱")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // 邮箱由 Apple ID 管理，提示用户去设置修改
                            showEditEmailAlert = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 协议勾选区域
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(agreedToTerms ? .blue : .gray)
                        .font(.system(size: 18))
                        .onTapGesture { agreedToTerms.toggle() }
                    HStack(spacing: 0) {
                        Text("已阅读并同意")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("📋 用户协议") {
                            showTermsOfService = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        Text("和")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("📄 隐私政策") {
                            showPrivacyPolicy = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .onTapGesture { agreedToTerms.toggle() }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            
            // 按钮区域
            VStack(spacing: 12) {
                // 确认并登录按钮
                Button(action: {
                    onConfirm()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("确认并登录")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(!agreedToTerms)
                
                // 取消按钮
                Button(action: {
                    // 关闭当前界面
                    dismiss()
                }) {
                    Text("取消")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("修改用户名", isPresented: $showEditNameAlert) {
            Button("去设置") {
                // 跨平台设置跳转 - 支持 Mac、iPhone、iPad，直接跳转到个人信息
                let possibleUrls = [
                    // iOS 18+ 新格式 - 个人信息（iPhone/iPad）
                    "App-Prefs:root=APPLE_ACCOUNT&path=NAME_AND_PHONE",
                    "App-Prefs:root=APPLE_ACCOUNT&path=NAME_PHONE_EMAIL",
                    "App-Prefs:root=APPLE_ACCOUNT&path=CONTACTS_AND_EMAIL",
                    
                    // iOS 17+ 格式 - 个人信息（iPhone/iPad）
                    "App-Prefs:root=APPLE_ACCOUNT&path=NAME_AND_PHONE",
                    "App-Prefs:root=APPLE_ACCOUNT&path=NAME_PHONE_EMAIL",
                    
                    // iOS 16+ 格式 - 个人信息（iPhone/iPad）
                    "App-Prefs:root=APPLE_ACCOUNT&path=NameAndPhone",
                    "App-Prefs:root=APPLE_ACCOUNT&path=NamePhoneEmail",
                    
                    // macOS 格式 - 个人信息（Mac）
                    "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?NameAndPhone",
                    "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane?NamePhoneEmail",
                    "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane",
                    
                    // macOS 备用格式（Mac）
                    "x-apple.systempreferences:com.apple.preferences.UsersGroupsPrefPane",
                    "x-apple.systempreferences:com.apple.preferences.internetaccounts",
                    
                    // 通用 Apple ID 主页面（所有平台）
                    "App-Prefs:root=APPLE_ACCOUNT",
                    
                    // iOS 通用设置页面（iPhone/iPad）
                    "App-Prefs:root=General&path=About",
                    "App-Prefs:root=General",
                    "App-Prefs:root=Privacy&path=CONTACTS",
                    "App-Prefs:root=Privacy",
                    
                    // macOS 系统偏好设置（Mac）
                    "x-apple.systempreferences:",
                    
                    // 最终备用 - 尝试打开设置应用
                    "App-Prefs:"
                ]
                
                // 记录跳转时间，用于检测用户返回
                UserDefaults.standard.set(Date(), forKey: "settings_jump_time")
                
                var jumpSuccess = false
                
                for urlString in possibleUrls {
                    if let settingsUrl = URL(string: urlString) {
                        if UIApplication.shared.canOpenURL(settingsUrl) {
                            UIApplication.shared.open(settingsUrl) { success in
                                if success {
                                } else {
                                }
                            }
                            jumpSuccess = true
                            break
                        } else {
                        }
                    }
                }
                
                if !jumpSuccess {
                    // 如果所有方式都失败，显示提示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // 可以在这里添加一个提示弹窗
                    }
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("用户名由 Apple ID 管理，请在系统设置中更改您的 Apple ID 用户名\n1. 点击'Apple ID'\n2. 选择'姓名、电话号码、电子邮件'\n3. 修改姓名")
        }
        .alert("更改邮箱", isPresented: $showEditEmailAlert) {
            Button("去设置") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl) { success in
                        if success {
                        } else {
                        }
                    }
                } else {
                }
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("邮箱地址由 Apple ID 管理，请在系统设置中更改您的 Apple ID 邮箱地址\n1. 点击'Apple ID'\n2. 选择'登录与安全性'\n3. 修改邮箱地址")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 应用重新激活时检查是否需要更新 Apple ID 信息
            userManager.checkAndUpdateAppleIDInfo()
        }
    }
}

// 个人信息界面
struct ProfileView: View {
    @ObservedObject var userManager: UserManager
    @ObservedObject var diamondManager: DiamondManager
    @Binding var showEditEmailAlert: Bool
    @Binding var showLogoutAlert: Bool
    @Binding var showRechargeSheet: Bool
    @Binding var newUserName: String
    let isUserBlacklisted: Bool
    let onClearAllHistory: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showGuestNameAlert = false // 新增：游客用户名提示alert
    @State private var showDeleteAccountAlert = false // 新增：删除账户确认alert
    @State private var showCreateInternalAccount = false // 新增：显示创建内部账号界面
    @State private var showReportRecordProcessing = false // 新增：显示举报记录处理界面
    @State private var showEditNameAlert = false // 本地处理用户名修改alert
    @State private var showAvatarZoom = false // 新增：显示头像放大查看界面
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 用户基本信息
                                    VStack(spacing: 15) {
                        HStack {
                            // 头像 - 可点击放大查看
                            Button(action: {
                                showAvatarZoom = true
                            }) {
                                // 检查是否有自定义头像
                                if let userId = userManager.currentUser?.id,
                                   let customAvatar = UserDefaults.standard.string(forKey: "custom_avatar_\(userId)") {
                                    // 显示自定义头像
                                    if customAvatar == "applelogo" {
                                        // Apple logo SF Symbol
                                        Image(systemName: customAvatar)
                                            .font(.system(size: 40))
                                            .foregroundColor(.black)
                                    } else if customAvatar == "person.circle.fill" {
                                        // Person circle SF Symbol
                                        Image(systemName: customAvatar)
                                            .font(.system(size: 40))
                                            .foregroundColor(userManager.currentUser?.loginType == .internal ? .purple : .blue)
                                    } else {
                                        // Emoji
                                        Text(customAvatar)
                                            .font(.system(size: 40))
                                    }
                                } else {
                                    // 显示默认头像
                                    let loginType = userManager.currentUser?.loginType
                                    let iconName = loginType == .apple ? "applelogo" : 
                                                 loginType == .`internal` ? "person.circle.fill" : "person.circle"
                                    let iconColor = loginType == .apple ? Color.black : 
                                                  loginType == .`internal` ? Color.purple : Color.blue
                                    
                                    Image(systemName: iconName)
                                        .font(.system(size: 40))
                                        .foregroundColor(iconColor)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                let userName = userManager.currentUser?.fullName ?? "用户"
                                Text("👋 \(userName)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                // 根据用户类型显示不同的编辑按钮
                                Button {
                                    let loginType = userManager.currentUser?.loginType
                                    if loginType == .guest {
                                        // 游客用户显示提示
                                        showGuestNameAlert = true
                                    } else if loginType == .`internal` {
                                        // 内部用户显示提示
                                        showGuestNameAlert = true
                                    } else {
                                        // Apple ID 用户显示提示
                                        showEditNameAlert = true
                                    }
                                } label: {
                                    Image(systemName: "pencil.circle")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                            
                            let loginType = userManager.currentUser?.loginType
                            let loginTypeText = loginType == .apple ? "Apple账户" : 
                                              loginType == .`internal` ? "内部用户" : "游客模式"
                            
                            Text("🔐 \(loginTypeText)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Apple ID 用户显示刷新按钮
                        let shouldShowRefreshButton = userManager.currentUser?.loginType == .apple
                        if shouldShowRefreshButton {
                            Button {
                                userManager.forceRefreshAppleIDInfo()
                            } label: {
                                Image(systemName: "arrow.clockwise.circle")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                        }
                    }
                    
                    // 邮箱信息
                    HStack {
                        if let email = userManager.currentUser?.email {
                            let emailText = "✉️ \(email)"
                            Text(emailText)
                                .font(.system(size: 17 * 2.26))
                                .foregroundColor(.gray)
                            
                            // 只有 Apple ID 用户才显示编辑按钮
                            let shouldShowEditButton = userManager.currentUser?.loginType == .apple
                            if shouldShowEditButton {
                                Button {
                                    showEditEmailAlert = true
                                } label: {
                                    Image(systemName: "pencil.circle")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                            }
                        } else {
                            Text("✉️ 无")
                                .font(.system(size: 17 * 2.26))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    
                    // Apple ID 用户特殊提示
                    let isAppleUserWithoutEmail = userManager.currentUser?.loginType == .apple && userManager.currentUser?.email == nil
                    if isAppleUserWithoutEmail {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("(隐私保护)")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("如需显示邮箱，请在系统设置中修改 Apple ID 邮箱")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    

                    

                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
                
                // 钻石信息
                VStack(spacing: 10) {
                    HStack {
                        if diamondManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.purple)
                        } else {
                            Text("💎 \(diamondManager.diamonds)")
                                .font(.title)
                                .foregroundColor(.purple)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        Button("充值") {
                            showRechargeSheet = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                    }
                    
                    Text("成功匹配时消耗1颗钻石")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(15)
                
                Spacer()
                
                // 只有内部账号登录时才显示创建测试账号按钮
                if userManager.currentUser?.loginType == .`internal` {
                    Button("🔐 创建测试账号") {
                        showCreateInternalAccount = true
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isUserBlacklisted ? Color.gray : Color.purple)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .disabled(isUserBlacklisted)
                    
                    // 举报记录处理按钮
                    Button("📋 举报记录处理") {
                        showReportRecordProcessing = true
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isUserBlacklisted ? Color.gray : Color.orange)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .disabled(isUserBlacklisted)
                }
                
                // 法律和帮助部分
                Button("📄 隐私政策") {
                    showPrivacyPolicy = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .contentShape(Rectangle())
                
                Button("📋 用户协议") {
                    showTermsOfService = true
                }
                .font(.caption)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .contentShape(Rectangle())
                
                // 删除账户按钮
                Button(action: {
                    showDeleteAccountAlert = true
                }) {
                    Text("删除账户")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                
                // 退出登录按钮
                Button(action: {
                    showLogoutAlert = true
                }) {
                    Text("退出登录")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            .padding()
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.inline)

            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showCreateInternalAccount) {
                CreateInternalAccountView()
            }
            .sheet(isPresented: $showReportRecordProcessing) {
                ReportRecordProcessingView(userManager: userManager)
            }
            .alert("提示", isPresented: $showGuestNameAlert) {
                Button("确定") { }
            } message: {
                let loginType = userManager.currentUser?.loginType
                let messageText = loginType == .`internal` ? 
                    "内部用户登录模式下，信息无法修改。如需修改信息，请联系管理员。" :
                    "游客登录模式下，信息无法修改。如需修改信息，请使用 Apple ID 登录。"
                Text(messageText)
            }
            .alert("修改用户名", isPresented: $showEditNameAlert) {
                Button("确定") { }
            } message: {
                Text("用户名由 Apple ID 管理，请在系统设置中更改您的 Apple ID 用户名\n1. 点击'Apple ID'\n2. 选择'姓名、电话号码、电子邮件'\n3. 修改姓名")
            }
            .alert("删除账户", isPresented: $showDeleteAccountAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteUserAccount()
                }
            } message: {
                Text("删除账户后，您的账户将在7天后自动删除。期间如果重新登录，删除请求将被取消。确定要删除账户吗？")
            }
            .sheet(isPresented: $showAvatarZoom) {
                AvatarZoomView(userManager: userManager, showRandomButton: true)
            }

        }
    }
    
    // 删除用户账户
    func deleteUserAccount() {
        guard let currentUser = userManager.currentUser else {
            return
        }
        
        // 获取设备ID
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        // 发送账户删除请求到LeanCloud
        LeanCloudService.shared.requestAccountDeletion(
            userId: currentUser.id,
            userName: currentUser.fullName,
            deviceId: deviceId
        ) { success in
            DispatchQueue.main.async {
                if success {
                    // 清除本地存储的用户信息
                    userManager.clearAppleIDStoredInfo()
                    // 清除历史记录
                    self.onClearAllHistory()
                    // 退出登录并关闭个人信息界面
                    userManager.logout()
                    dismiss()
                } else {
                    // 即使发送失败，也清除本地数据并退出登录
                    userManager.clearAppleIDStoredInfo()
                    // 清除历史记录
                    self.onClearAllHistory()
                    userManager.logout()
                    dismiss()
                }
            }
        }
    }
    

}

#Preview {
    ContentView()
}

// MARK: - 游客信息确认视图
struct GuestInfoConfirmationView: View {
    @Binding var displayName: String
    @Binding var email: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @State private var editingName = false
    @State private var editingEmail = false
    @State private var showEditAlert = false
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    @FocusState private var nameFieldFocused: Bool
    @FocusState private var emailFieldFocused: Bool
    @State private var agreedToTerms = false

    var body: some View {
        VStack(spacing: 30) {
            // 标题
            Text("游客信息确认")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)
            // 头像
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            // 用户信息卡片
            VStack(spacing: 20) {
                // 用户名
                VStack(alignment: .leading, spacing: 8) {
                    Text("用户名")
                        .font(.headline)
                        .foregroundColor(.gray)
                    HStack {
                        if editingName {
                            TextField("请输入用户名", text: $displayName)
                                .font(.title2)
                                .fontWeight(.medium)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($nameFieldFocused)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onSubmit { editingName = false }
                                .onAppear { DispatchQueue.main.async { nameFieldFocused = true } }
                        } else {
                            Text(displayName.isEmpty ? "未填写" : displayName)
                                .font(.title2)
                                .fontWeight(.medium)
                        }
                        Spacer()
                        Button(action: {
                            showEditAlert = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    Text("该名称将用于与其他用户匹配时显示")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                // 邮箱
                VStack(alignment: .leading, spacing: 8) {
                    Text("邮箱地址（可选）")
                        .font(.headline)
                        .foregroundColor(.gray)
                    HStack {
                        if editingEmail {
                            TextField("请输入邮箱地址", text: $email)
                                .font(.title2)
                                .textFieldStyle(PlainTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($emailFieldFocused)
                                .onSubmit { editingEmail = false }
                                .onAppear { DispatchQueue.main.async { emailFieldFocused = true } }
                        } else {
                            Text(email.isEmpty ? "未填写" : email)
                                .font(.title2)
                                .foregroundColor(email.isEmpty ? .gray : .blue)
                        }
                        Spacer()
                        Button(action: {
                            showEditAlert = true
                        }) {
                            Image(systemName: "pencil.circle")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            Spacer()
            
            // 协议勾选区域
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(agreedToTerms ? .blue : .gray)
                        .font(.system(size: 18))
                        .onTapGesture { agreedToTerms.toggle() }
                    HStack(spacing: 0) {
                        Text("已阅读并同意")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("📋 用户协议") {
                            showTermsOfService = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        Text("和")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Button("📄 隐私政策") {
                            showPrivacyPolicy = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .onTapGesture { agreedToTerms.toggle() }
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            
            // 按钮区域
            VStack(spacing: 12) {
                Button(action: {
                    onConfirm()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("确认并登录")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !agreedToTerms)
                Button(action: {
                    onCancel()
                }) {
                    Text("取消")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .alert("提示", isPresented: $showEditAlert) {
            Button("确定") { }
        } message: {
            Text("游客登录模式下，信息无法修改。如需修改信息，请使用 Apple ID 登录。")
        }
    }
}

// 举报记录处理界面
struct ReportRecordProcessingView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var reportRecords: [ReportRecordUI] = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("举报记录处理")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("查看和处理用户举报记录")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                if isLoading {
                    Spacer()
                    ProgressView("加载中...")
                        .scaleEffect(1.2)
                    Spacer()
                } else if reportRecords.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("暂无举报记录")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("当前没有待处理的举报记录")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    // 举报记录列表
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(reportRecords, id: \.id) { record in
                                ReportRecordCard(record: record) { action in
                                    handleReportAction(record: record, action: action)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 底部按钮
                HStack(spacing: 15) {
                    Button("刷新") {
                        loadReportRecords()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(isLoading)
                    
                    Button("关闭") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("举报记录处理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("处理结果", isPresented: $showAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadReportRecords()
            }
        }
    }
    
    // 加载举报记录
    private func loadReportRecords() {
        isLoading = true
        
        // 清理本地已处理记录
        cleanupProcessedRecords()
        
        // 调用LeanCloud服务获取真实举报记录
        LeanCloudService.shared.fetchReportRecords { reportRecords, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ 获取举报记录失败: \(error)")
                    self.alertMessage = "获取举报记录失败: \(error)"
                    self.showAlert = true
                    return
                }
                
                if let reportRecords = reportRecords {
                    // 获取当前用户的已处理记录ID列表
                    let currentUserKey = getProcessedRecordsKey()
                    let processedRecordIds = UserDefaults.standard.stringArray(forKey: currentUserKey) ?? []
                    
                    // 过滤掉被举报人是内部用户的记录和已处理的记录
                    let filteredRecords = reportRecords.filter { record in
                        record.reportedUserLoginType != "internal" && 
                        !processedRecordIds.contains(record.id)
                    }
                    
                    // 转换为UI数据模型
                    self.reportRecords = filteredRecords.map { record in
                        ReportRecordUI(
                            id: record.id,
                            reporterName: record.reporterUserName,
                            reportedName: record.reportedUserName,
                            reportedUserLoginType: record.reportedUserLoginType,
                            reason: record.reportReason,
                            description: "举报时间: \(formatDate(record.reportTime))",
                            status: "待处理",
                            createdAt: record.reportTime
                        )
                    }
                    print("📋 成功加载 \(self.reportRecords.count) 条举报记录（已过滤内部用户举报和已处理记录）")
                } else {
                    self.reportRecords = []
                    print("📋 没有找到举报记录")
                }
            }
        }
    }
    
    // 清理本地已处理记录（保留最近1000条）
    private func cleanupProcessedRecords() {
        let currentUserKey = getProcessedRecordsKey()
        let processedRecordIds = UserDefaults.standard.stringArray(forKey: currentUserKey) ?? []
        if processedRecordIds.count > 1000 {
            let recentRecords = Array(processedRecordIds.suffix(1000))
            UserDefaults.standard.set(recentRecords, forKey: currentUserKey)
            print("🧹 已清理当前用户的已处理记录，保留最近1000条")
        }
    }
    
    // 获取当前用户的已处理记录键名
    private func getProcessedRecordsKey() -> String {
        guard let currentUser = userManager.currentUser else {
            // 如果没有当前用户，使用设备ID作为备用
            let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
            let shortDeviceID = String(deviceID.prefix(8))
            return "processed_report_record_ids_\(shortDeviceID)"
        }
        
        // 根据用户类型和ID生成唯一的键名
        switch currentUser.loginType {
        case .apple:
            let email = currentUser.email ?? "unknown"
            return "processed_report_record_ids_apple_\(email)"
        case .internal:
            return "processed_report_record_ids_internal_\(currentUser.id)"
        case .guest:
            let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
            let shortDeviceID = String(deviceID.prefix(8))
            return "processed_report_record_ids_guest_\(shortDeviceID)"
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    
    // 处理举报操作
    private func handleReportAction(record: ReportRecordUI, action: ReportAction) {
        let actionString: String
        switch action {
        case .reject:
            actionString = "rejected"
            alertMessage = "已驳回举报：\(record.reportedName)"
        case .warn:
            actionString = "warned"
            alertMessage = "已警告用户：\(record.reportedName)"
        case .ban:
            actionString = "banned"
            alertMessage = "已封禁用户：\(record.reportedName)"
        }
        
        // 调用LeanCloud服务处理举报记录
        LeanCloudService.shared.processReportRecord(recordId: record.id, action: actionString) { success, error in
            DispatchQueue.main.async {
                if success {
                    // 保存已处理的记录ID到当前用户的本地存储
                    let currentUserKey = getProcessedRecordsKey()
                    var processedRecordIds = UserDefaults.standard.stringArray(forKey: currentUserKey) ?? []
                    processedRecordIds.append(record.id)
                    UserDefaults.standard.set(processedRecordIds, forKey: currentUserKey)
                    
                    // 从当前列表中移除已处理的记录
                    self.reportRecords.removeAll { $0.id == record.id }
                    
                    print("✅ 举报记录处理成功，已从列表中移除")
                } else {
                    print("❌ 举报记录处理失败: \(error ?? "未知错误")")
                    self.alertMessage = "处理失败: \(error ?? "未知错误")"
                }
                self.showAlert = true
            }
        }
    }
}

// 举报记录UI数据模型
struct ReportRecordUI {
    let id: String
    let reporterName: String
    let reportedName: String
    let reportedUserLoginType: String? // 被举报用户的用户类型
    let reason: String
    let description: String
    var status: String
    let createdAt: Date
}

// 举报操作类型
enum ReportAction {
    case reject
    case warn
    case ban
}

// 举报记录卡片视图
struct ReportRecordCard: View {
    let record: ReportRecordUI
    let onAction: (ReportAction) -> Void
    @State private var showActionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部信息
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    // 被举报人信息
                    HStack(spacing: 12) {
                        // 被举报人头像
                        ZStack {
                            Circle()
                                .fill(getUserTypeColor(record.reportedUserLoginType))
                                .frame(width: 40, height: 40)
                            
                            if let loginType = record.reportedUserLoginType {
                                if loginType == "apple" {
                                    Image(systemName: "applelogo")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .medium))
                                } else if loginType == "internal" {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .medium))
                                } else {
                                    Text("👥")
                                        .font(.system(size: 18))
                                }
                            } else {
                                Text("👥")
                                    .font(.system(size: 18))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("被举报人：\(record.reportedName)")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            if let loginType = record.reportedUserLoginType {
                                Text(getUserTypeText(loginType))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(getUserTypeBackground(loginType))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                Spacer()
                StatusBadge(status: record.status)
            }
            
            // 举报原因
            VStack(alignment: .leading, spacing: 4) {
                Text("举报原因：\(record.reason)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(record.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 操作按钮
            if record.status == "待处理" {
                Button("处理举报") {
                    showActionSheet = true
                }
                .font(.caption)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .actionSheet(isPresented: $showActionSheet) {
            ActionSheet(
                title: Text("处理举报"),
                message: Text("选择处理方式"),
                buttons: [
                    .default(Text("驳回举报")) { onAction(.reject) },
                    .default(Text("警告用户")) { onAction(.warn) },
                    .destructive(Text("封禁用户")) { onAction(.ban) },
                    .cancel()
                ]
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // 获取用户类型显示文本
    private func getUserTypeText(_ loginType: String?) -> String {
        switch loginType {
        case "apple":
            return "Apple ID用户"
        case "internal":
            return "内部用户"
        case "guest":
            return "游客用户"
        default:
            return "未知用户"
        }
    }
    
    // 获取用户类型背景颜色
    private func getUserTypeBackground(_ loginType: String?) -> Color {
        switch loginType {
        case "apple":
            return Color.black.opacity(0.1)
        case "internal":
            return Color.purple.opacity(0.1)
        case "guest":
            return Color.blue.opacity(0.1)
        default:
            return Color.gray.opacity(0.1)
        }
    }
    
    // 获取用户类型头像颜色
    private func getUserTypeColor(_ loginType: String?) -> Color {
        switch loginType {
        case "apple":
            return Color.black
        case "internal":
            return Color.purple
        case "guest":
            return Color.blue
        default:
            return Color.gray
        }
    }
}

// 状态标签视图
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(status == "待处理" ? .orange : .green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status == "待处理" ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
            .cornerRadius(8)
    }
}

// 头像放大显示视图
struct AvatarZoomView: View {
    @ObservedObject var userManager: UserManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentAvatarEmoji: String? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var timer: Timer?
    let showRandomButton: Bool // 控制是否显示随机切换按钮
    
    // 添加一个计算属性来获取当前头像
    private var displayAvatar: String? {
        return currentAvatarEmoji
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // 放大的头像
                if let customAvatar = displayAvatar {
                    // 显示自定义头像
                    if customAvatar == "applelogo" {
                        // Apple logo SF Symbol
                        Image(systemName: customAvatar)
                            .font(.system(size: 120))
                            .foregroundColor(.black)
                            .onAppear {
                                print("🎨 显示自定义Apple logo头像")
                            }
                    } else if customAvatar == "person.circle.fill" {
                        // Person circle SF Symbol
                        Image(systemName: customAvatar)
                            .font(.system(size: 120))
                            .foregroundColor(userManager.currentUser?.loginType == .internal ? .purple : .blue)
                            .onAppear {
                                print("🎨 显示自定义Person circle头像")
                            }
                    } else {
                        // Emoji
                        Text(customAvatar)
                            .font(.system(size: 120))
                            .onAppear {
                                print("🎨 显示自定义emoji头像: \(customAvatar)")
                            }
                    }
                } else if let loginType = userManager.currentUser?.loginType {
                    // 显示默认头像
                    if loginType == .apple {
                        Image(systemName: "applelogo")
                            .foregroundColor(.black)
                            .font(.system(size: 120))
                    } else if loginType == .`internal` {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 120))
                    } else {
                        Image(systemName: "person.circle")
                            .foregroundColor(.blue)
                            .font(.system(size: 120))
                    }
                }
                
                // 用户信息
                VStack(spacing: 10) {
                    Text(userManager.currentUser?.fullName ?? "未知用户")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let loginType = userManager.currentUser?.loginType {
                        let loginTypeText = loginType == .apple ? "Apple账户" : 
                                          loginType == .`internal` ? "内部用户" : "游客模式"
                        Text(loginTypeText)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    
                    if let email = userManager.currentUser?.email, !email.isEmpty {
                        Text(email)
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
                
                // 随机切换头像按钮 - 只在指定情况下显示
                if showRandomButton {
                    Button(action: {
                        print("🔘 随机切换头像按钮被点击")
                        randomizeAvatar()
                    }) {
                        HStack {
                            Image(systemName: "dice.fill")
                            Text("随机切换头像")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("用户头像")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("关闭") {
                dismiss()
            })
            .alert("提示", isPresented: $showAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // 初始化头像显示
                print("🎭 AvatarZoomView 视图加载")
                
                // 加载已保存的头像
                if currentAvatarEmoji == nil {
                    if let userId = userManager.currentUser?.id,
                       let savedEmoji = UserDefaults.standard.string(forKey: "custom_avatar_\(userId)") {
                        currentAvatarEmoji = savedEmoji
                        print("🎭 从UserDefaults加载头像: \(savedEmoji)")
                    } else {
                        print("🎭 初始化头像显示，当前为nil")
                    }
                } else {
                    print("🎭 当前头像: \(currentAvatarEmoji ?? "nil")")
                }
                
                // 启动定时器，每3秒输出当前状态
                timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                    print("⏰ 定时器检查 - currentAvatarEmoji: \(currentAvatarEmoji ?? "nil")")
                    print("⏰ 定时器检查 - displayAvatar: \(displayAvatar ?? "nil")")
                }
            }
            .onDisappear {
                // 停止定时器
                timer?.invalidate()
                timer = nil
            }

        }
    }
    

    
    // 随机切换头像
    private func randomizeAvatar() {
        print("🎲 开始随机切换头像...")
        
        // 检查钻石是否足够
        guard let diamondManager = userManager.diamondManager else {
            print("❌ 钻石管理器未初始化")
            alertMessage = "钻石管理器未初始化"
            showAlert = true
            return
        }
        
        print("💎 当前钻石数量: \(diamondManager.diamonds)")
        
        if !diamondManager.hasEnoughDiamonds(1) {
            print("❌ 钻石不足，需要1颗钻石才能随机切换头像")
            alertMessage = "钻石不足，需要1颗钻石才能随机切换头像"
            showAlert = true
            return
        }
        
        // 消耗钻石
        if diamondManager.spendDiamonds(1) {
            print("💎 钻石扣除成功，剩余钻石: \(diamondManager.diamonds)")
            
            // 随机选择一个emoji
            let randomEmoji = EmojiList.allEmojis.randomElement() ?? "😀"
            print("🎲 随机选择的emoji: \(randomEmoji)")
            
            // 更新本地状态
            currentAvatarEmoji = randomEmoji
            print("📱 本地头像已更新为: \(randomEmoji)")
            print("📱 currentAvatarEmoji状态: \(currentAvatarEmoji ?? "nil")")
            print("📱 displayAvatar状态: \(displayAvatar ?? "nil")")
            
            // 保存到UserDefaults
            if let userId = userManager.currentUser?.id {
                UserDefaults.standard.set(randomEmoji, forKey: "custom_avatar_\(userId)")
                print("💾 头像已保存到UserDefaults: custom_avatar_\(userId) = \(randomEmoji)")
            }
            
            // 更新到服务器
            if let userId = userManager.currentUser?.id,
               let loginType = userManager.currentUser?.loginType {
                let loginTypeString: String
                switch loginType {
                case .apple:
                    loginTypeString = "apple"
                case .guest:
                    loginTypeString = "guest"
                case .internal:
                    loginTypeString = "internal"
                }
                
                LeanCloudService.shared.updateUserAvatarRecord(userId: userId, loginType: loginTypeString, userAvatar: randomEmoji) { success in
                    if success {
                        print("✅ 头像已更新到服务器")
                    } else {
                        print("❌ 头像更新到服务器失败")
                    }
                }
            }
            
            // 强制UI刷新
            DispatchQueue.main.async {
                print("🔄 强制UI刷新")
            }
            
            // 更新头像到LeanCloud
            if let currentUser = userManager.currentUser {
                let loginType = currentUser.loginType == .apple ? "apple" : 
                               currentUser.loginType == .internal ? "internal" : "guest"
                
                print("☁️ 开始更新头像到LeanCloud...")
                print("   📄 用户ID: \(currentUser.id)")
                print("   📄 登录类型: \(loginType)")
                print("   📄 新头像: \(randomEmoji)")
                
                // TODO: 实现LeanCloud头像更新功能
                print("⚠️ LeanCloud头像更新功能暂未实现")
                DispatchQueue.main.async {
                    print("✅ 本地头像已更新")
                }
            } else {
                print("❌ 当前用户信息为空")
            }
            
            // 不显示成功提示框，直接更新头像
        } else {
            print("❌ 钻石扣除失败")
            alertMessage = "钻石扣除失败，请重试"
            showAlert = true
        }
    }
}
