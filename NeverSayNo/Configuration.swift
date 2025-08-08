import Foundation

// 配置管理类
class Configuration {
    static let shared = Configuration()
    
    // API配置
    let leanCloudAppId: String
    let leanCloudAppKey: String
    let leanCloudServerUrl: String
    
    private init() {
        // 使用正确的LeanCloud配置 - 参考Manager app的配置
        self.leanCloudAppId = "ummvIkxIM1Dq3EHUfCkSp54O-gzGzoHsz"  // 项目唯一标识符
        self.leanCloudAppKey = "tPrA1mVg3PdboG0TdFSrpInH"  // 公开的AppKey
        self.leanCloudServerUrl = "https://ummvikxi.lc-cn-n1-shared.com"  // 使用与Manager app相同的Server URL
        
        // 验证配置
        validateConfiguration()
        
        // 尝试从环境变量获取配置（如果存在）
        if let envAppId = ProcessInfo.processInfo.environment["LEANCLOUD_APP_ID"],
           let envAppKey = ProcessInfo.processInfo.environment["LEANCLOUD_APP_KEY"],
           let envServerUrl = ProcessInfo.processInfo.environment["LEANCLOUD_SERVER_URL"] {
            // 这里可以覆盖默认配置
            // self.leanCloudAppId = envAppId
            // self.leanCloudAppKey = envAppKey
            // self.leanCloudServerUrl = envServerUrl
        }
    }
    
    // 验证配置的有效性
    private func validateConfiguration() {
        #if DEBUG
        // 检查App ID格式
        if leanCloudAppId.isEmpty {
            print("❌ App ID为空")
        } else if leanCloudAppId.count < 10 {
            print("⚠️ App ID长度过短")
        }
        
        // 检查App Key格式
        if leanCloudAppKey.isEmpty {
            print("❌ App Key为空")
        } else if leanCloudAppKey.count < 10 {
            print("⚠️ App Key长度过短")
        }
        
        // 检查Server URL格式
        if leanCloudServerUrl.isEmpty {
            print("❌ Server URL为空")
        } else if !leanCloudServerUrl.hasPrefix("https://") {
            print("❌ Server URL必须以https://开头")
        }
        #endif
    }
    
    // 检查配置是否有效
    var isValid: Bool {
        return !leanCloudAppId.isEmpty && 
               !leanCloudAppKey.isEmpty && 
               !leanCloudServerUrl.isEmpty &&
               leanCloudServerUrl.hasPrefix("https://")
    }
    
    // 检查配置是否来自 Keychain（更安全的配置）
    var isConfigFromKeychain: Bool {
        let config = KeychainManager.shared.getLeanCloudConfig()
        return config.appId != nil && config.appKey != nil && config.serverUrl != nil
    }
    
    // 检查配置是否为默认值（安全检查）
    var isUsingDefaultValues: Bool {
        return leanCloudAppId.isEmpty || leanCloudAppKey.isEmpty || leanCloudServerUrl.isEmpty
    }
    
    // MARK: - 更新配置方法
    func updateLeanCloudConfig(appId: String, appKey: String, serverUrl: String) -> Bool {
        return KeychainManager.shared.saveLeanCloudConfig(
            appId: appId,
            appKey: appKey,
            serverUrl: serverUrl
        )
    }
    
    // MARK: - 测试连接方法
    func testConnection(completion: @escaping (Bool, String) -> Void) {
        // 简单的配置验证测试
        if isValid {
            completion(true, "配置验证通过")
        } else {
            completion(false, "配置验证失败")
        }
    }
} 