import Foundation
import UIKit
import CoreLocation

// LeanCloud服务类
class LeanCloudService: ObservableObject {
    // LeanCloud配置 - 使用配置管理类
    private let appId: String
    private let appKey: String
    private let serverUrl: String
    
    // 单例模式
    static let shared = LeanCloudService()
    
    private init() {
        // 从配置管理类获取API密钥
        let config = Configuration.shared
        
        #if DEBUG
        if !config.isValid {
            print("⚠️ 警告：LeanCloud配置无效")
            print("App ID: \(config.leanCloudAppId)")
            print("App Key: \(config.leanCloudAppKey)")
            print("Server URL: \(config.leanCloudServerUrl)")
        }
        #else
        guard config.isValid else {
            fatalError("LeanCloud配置无效，请检查API密钥配置")
        }
        #endif
        
        // 使用正确的LeanCloud配置
        self.appId = config.leanCloudAppId
        self.appKey = config.leanCloudAppKey
        self.serverUrl = config.leanCloudServerUrl
    }
    
    // 计算考虑时区的实际时间差（分钟）
    private func calculateTimeDifferenceWithTimezone(
        recordTime: Date,
        recordLongitude: Double,
        currentLongitude: Double,
        currentTime: Date
    ) -> Double {
        // 计算两个位置的时区偏移量（小时）
        let recordTimezoneOffset = Int(round(recordLongitude / 15.0))
        let currentTimezoneOffset = Int(round(currentLongitude / 15.0))
        
        // 限制在合理范围内
        let clampedRecordOffset = max(-12, min(14, recordTimezoneOffset))
        let clampedCurrentOffset = max(-12, min(14, currentTimezoneOffset))
        
        // 计算时区差（小时）
        let timezoneDifference = Double(clampedRecordOffset - clampedCurrentOffset)
        
        // 将记录时间转换为当前用户时区的时间
        let adjustedRecordTime = recordTime.addingTimeInterval(timezoneDifference * 3600)
        
        // 计算实际时间差（分钟）
        let actualTimeDifference = abs(currentTime.timeIntervalSince(adjustedRecordTime)) / 60
        
        return actualTimeDifference
    }
    
    // 生成ACL权限配置 - 修复权限问题
    private func generateACL() -> [String: Any] {
        // 使用LeanCloud标准的ACL格式
        return [
            "*": [
                "read": true,
                "write": true
            ]
        ]
    }
    
    // 为数据添加ACL权限
    private func addACLToData(_ data: [String: Any]) -> [String: Any] {
        let dataWithACL = data
        // 暂时注释掉ACL，避免格式错误
        // dataWithACL["ACL"] = generateACL()
        return dataWithACL
    }
    
    // 设置LeanCloud请求头 - 修复请求头格式，与Manager app保持一致
    private func setLeanCloudHeaders(_ request: inout URLRequest, contentType: String? = nil) {
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.setValue(appId, forHTTPHeaderField: "X-LC-Id")
        request.setValue(appKey, forHTTPHeaderField: "X-LC-Key")
        request.setValue("NeverSayNo/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
    }
    
    // 创建LocationRecord字段
    private func createLocationRecordFields(completion: @escaping (Bool) -> Void) {
        print("🔧 尝试创建LocationRecord字段...")
        
        // 创建一个测试记录来初始化字段
        let testData: [String: Any] = [
            "latitude": 0.0,
            "longitude": 0.0,
            "accuracy": 0.0,
            "user_id": "field_init",
            "user_name": "Field Initialization",
            "login_type": "guest",
            "user_email": "",
            "user_avatar": "👤",
            "device_id": "field_init_device",
            "timezone": "UTC",
            "device_time": ISO8601DateFormatter().string(from: Date())
        ]
        
        let urlString = "\(serverUrl)/1.1/classes/LocationRecord"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request, contentType: "application/json")
        request.timeoutInterval = 10.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testData)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 字段创建失败: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    #if DEBUG
                    print("📥 LeanCloud响应(初始上传): 状态码=\(httpResponse.statusCode)")
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        print("📨 响应体:\n\(body)")
                    }
                    #endif
                    if httpResponse.statusCode == 201 {
                        print("✅ LocationRecord字段创建成功")
                        completion(true)
                    } else {
                        print("❌ 字段创建失败，状态码: \(httpResponse.statusCode)")
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    print("📄 错误详情: \(error)")
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 使用简化数据发送位置信息（不包含新字段）
    private func sendLocationWithSimplifiedData(locationData: [String: Any], completion: @escaping (Bool, String) -> Void) {
        print("📤 使用简化数据发送位置信息...")
        
        // 提取基本字段，并确保包含用户头像
        let userIdInData = (locationData["user_id"] as? String) ?? ""
        let avatarInData = (locationData["user_avatar"] as? String)
            ?? UserDefaults.standard.string(forKey: "custom_avatar_\(userIdInData)")
            ?? "👤"
        let simplifiedData: [String: Any] = [
            "latitude": locationData["latitude"] ?? 0.0,
            "longitude": locationData["longitude"] ?? 0.0,
            "accuracy": locationData["accuracy"] ?? 0.0,
            "user_id": locationData["user_id"] ?? "",
            "user_name": locationData["user_name"] ?? "",
            "login_type": locationData["login_type"] ?? "",
            "user_email": locationData["user_email"] ?? "",
            "user_avatar": avatarInData,
            "device_id": locationData["device_id"] ?? "",
            "timezone": locationData["timezone"] ?? "",
            "device_time": locationData["device_time"] ?? ""
        ]
        
        let urlString = "\(serverUrl)/1.1/classes/LocationRecord"
        guard let url = URL(string: urlString) else {
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request, contentType: "application/json")
        request.timeoutInterval = 10.0
        
        // 为位置数据添加ACL权限
        let locationDataWithACL = addACLToData(simplifiedData)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: locationDataWithACL)
            #if DEBUG
            if let pretty = try? JSONSerialization.data(withJSONObject: locationDataWithACL, options: [.prettyPrinted]),
               let bodyString = String(data: pretty, encoding: .utf8) {
                print("🔼 准备上传 LocationRecord → \(urlString)")
                print("📦 请求体:\n\(bodyString)")
            }
            #endif
        } catch {
            completion(false, "数据编码失败: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "连接失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    #if DEBUG
                    print("📥 LeanCloud响应(简化上传): 状态码=\(httpResponse.statusCode)")
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        print("📨 响应体:\n\(body)")
                    }
                    #endif
                    if httpResponse.statusCode == 201 {
                        print("✅ 简化数据上传成功")
                        completion(true, "")
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        completion(false, errorMessage)
                    }
                } else {
                    completion(false, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 处理403 Forbidden错误 - 详细的错误诊断
    private func handle403ForbiddenError(_ request: URLRequest, _ httpResponse: HTTPURLResponse, _ data: Data, operation: String) {
        #if DEBUG
        print("🚫 403 Forbidden 错误详情:")
        print("   📍 操作: \(operation)")
        print("   🌐 URL: \(request.url?.absoluteString ?? "未知")")
        print("   📋 请求方法: \(request.httpMethod ?? "未知")")
        print("   🔑 App ID: \(appId)")
        print("   🔑 App Key: \(appKey)")
        print("   📋 实际请求头:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("     \(key): \(value)")
        }
        print("   📊 HTTP状态码: \(httpResponse.statusCode)")
        print("   📋 响应头:")
        for (key, value) in httpResponse.allHeaderFields {
            print("     \(key): \(value)")
        }
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("   📄 响应数据大小: \(data.count) bytes")
            if data.count < 1000 {
                print("   📄 响应内容: \(responseString)")
            }
        }
        
        print("   🔍 可能的原因:")
        print("     - App Key权限不足")
        print("     - ACL权限配置问题")
        print("     - 服务器端权限设置")
        print("     - 请求头格式错误")
        print("     - 数据格式不符合要求")
        #endif
    }
    
    // 处理403错误（别名函数，保持向后兼容）
    private func handle403Error(_ httpResponse: HTTPURLResponse, _ data: Data?, _ request: URLRequest, _ operation: String) {
        if let data = data {
            handle403ForbiddenError(request, httpResponse, data, operation: operation)
        }
    }
    
    // 处理网络错误 - 详细的错误诊断
    private func handleNetworkError(_ error: Error, _ request: URLRequest, operation: String) {
        #if DEBUG
        print("🌐 网络错误详情:")
        print("   📍 操作: \(operation)")
        print("   🌐 URL: \(request.url?.absoluteString ?? "未知")")
        print("   📋 请求方法: \(request.httpMethod ?? "未知")")
        print("   🔑 App ID: \(appId)")
        print("   🔑 App Key: \(appKey)")
        print("   ❌ 错误类型: \(type(of: error))")
        print("   📝 错误描述: \(error.localizedDescription)")
        
        if let nsError = error as NSError? {
            print("   🔢 错误代码: \(nsError.code)")
            print("   🏷️ 错误域: \(nsError.domain)")
            
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("   🔗 底层错误: \(underlyingError.localizedDescription)")
                print("   🔢 底层错误代码: \(underlyingError.code)")
            }
        }
        
        print("   🔍 可能的原因:")
        print("     - DNS解析失败")
        print("     - 网络连接问题")
        print("     - 服务器不可达")
        print("     - 防火墙阻止")
        print("     - 网络配置问题")
        #endif
    }
    
    // 验证API配置
    private func validateAPIConfig() -> Bool {
        if appId.isEmpty {
            print("❌ App ID为空")
            return false
        }
        
        if appKey.isEmpty {
            print("❌ App Key为空")
            return false
        }
        
        if serverUrl.isEmpty {
            print("❌ Server URL为空")
            return false
        }
        
        if !serverUrl.hasPrefix("https://") {
            print("❌ Server URL必须以https://开头")
            return false
        }
        
        return true
    }
    
    // 验证API密钥（别名函数，保持向后兼容）
    private func validateApiCredentials() -> Bool {
        return validateAPIConfig()
    }
    
    // 测试API配置
    func testAPIConfig() -> Bool {
        if validateAPIConfig() {
            return true
        } else {
            #if DEBUG
            print("❌ API配置验证失败")
            print("App ID: \(appId.isEmpty ? "空" : "已设置")")
            print("App Key: \(appKey.isEmpty ? "空" : "已设置")")
            print("Server URL: \(serverUrl.isEmpty ? "空" : serverUrl)")
            #endif
            return false
        }
    }
    
    // 发送位置数据到LeanCloud
    func sendLocation(locationData: [String: Any], completion: @escaping (Bool, String) -> Void) {
        // 验证API密钥
        guard validateApiCredentials() else {
            #if DEBUG
            print("❌ API配置验证失败")
            print("App ID: \(appId.isEmpty ? "空" : "已设置")")
            print("App Key: \(appKey.isEmpty ? "空" : "已设置")")
            print("Server URL: \(serverUrl.isEmpty ? "空" : serverUrl)")
            #endif
            completion(false, "API密钥配置错误")
            return
        }
        
        let urlString = "\(serverUrl)/1.1/classes/LocationRecord"
        guard let url = URL(string: urlString) else {
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request, contentType: "application/json")
        request.timeoutInterval = 10.0
        
        // 为位置数据添加ACL权限
        let locationDataWithACL = addACLToData(locationData)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: locationDataWithACL)
            #if DEBUG
            if let pretty = try? JSONSerialization.data(withJSONObject: locationDataWithACL, options: [.prettyPrinted]),
               let bodyString = String(data: pretty, encoding: .utf8) {
                print("🔼 准备上传 简化 LocationRecord → \(urlString)")
                print("📦 请求体:\n\(bodyString)")
            }
            #endif
        } catch {
            completion(false, "数据编码失败: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // 详细的网络错误处理
                    self.handleNetworkError(error, request, operation: "发送位置数据")
                    completion(false, "连接失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        // 成功创建记录
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                _ = json?["objectId"] as? String
                                completion(true, "")
                            } catch {
                                completion(true, "")
                            }
                        } else {
                            completion(true, "")
                        }
                    } else if httpResponse.statusCode == 403 {
                        // 检查是否是字段权限错误
                        var isFieldPermissionError = false
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    if error.contains("Forbidden to add new fields") {
                                        isFieldPermissionError = true
                                        // 字段创建失败，使用简化数据重试
                                        print("⚠️ 无法创建新字段，使用简化数据重试...")
                                        self.sendLocationWithSimplifiedData(locationData: locationData, completion: completion)
                                        return
                                    }
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        
                        // 如果不是字段权限错误，按原来的方式处理
                        self.handle403Error(httpResponse, data, request, "发送位置数据")
                        var errorMessage = "权限错误: 403 Forbidden"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud权限错误: \(error)"
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        completion(false, errorMessage)
                    } else if httpResponse.statusCode == 401 {
                        // 详细处理401错误
                        #if DEBUG
                        print("❌ 401 Unauthorized 错误详情:")
                        print("   📍 操作: 发送位置数据")
                        print("   🌐 URL: \(request.url?.absoluteString ?? "未知")")
                        print("   📋 请求方法: \(request.httpMethod ?? "未知")")
                        print("   🔑 App ID: \(self.appId)")
                        print("   🔑 App Key: \(self.appKey)")
                        print("   📋 实际请求头:")
                        for (key, value) in request.allHTTPHeaderFields ?? [:] {
                            print("     \(key): \(value)")
                        }
                        print("   📊 HTTP状态码: \(httpResponse.statusCode)")
                        print("   📋 响应头:")
                        for (key, value) in httpResponse.allHeaderFields {
                            print("     \(key): \(value)")
                        }
                        
                        if let data = data {
                            print("   📄 响应数据大小: \(data.count) bytes")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("   📄 响应内容: \(responseString)")
                            }
                        }
                        
                        print("   🔍 可能的原因:")
                        print("     - App Key格式错误")
                        print("     - App Key权限不足")
                        print("     - 服务器端认证配置问题")
                        print("     - 请求头格式错误")
                        #endif
                        
                        var errorMessage = "认证失败: 401 Unauthorized"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud认证错误: \(error)"
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        
                        completion(false, errorMessage)
                    } else {
                        // 处理其他错误响应
                        #if DEBUG
                        print("❌ 服务器错误: \(httpResponse.statusCode)")
                        print("   📍 操作: 发送位置数据")
                        print("   🌐 URL: \(request.url?.absoluteString ?? "未知")")
                        print("   📊 HTTP状态码: \(httpResponse.statusCode)")
                        
                        if let data = data {
                            print("   📄 响应数据大小: \(data.count) bytes")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("   📄 响应内容: \(responseString)")
                            }
                        }
                        #endif
                        
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        completion(false, errorMessage)
                    }
                } else {
                    completion(false, "无效的响应")
                }
            }
        }.resume()
    }
    
    // 从LeanCloud获取位置记录
    func fetchLocations(completion: @escaping ([LocationRecord]?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/LocationRecord?order=-createdAt&limit=1000"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // 详细的网络错误处理
                    self.handleNetworkError(error, request, operation: "获取位置记录")
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]] {
                                let records = results.compactMap { locationDict -> LocationRecord? in
                                    guard let objectId = locationDict["objectId"] as? String,
                                          let latitude = locationDict["latitude"] as? Double,
                                          let longitude = locationDict["longitude"] as? Double,
                                          let userId = locationDict["user_id"] as? String,
                                          let deviceId = locationDict["device_id"] as? String else {
                                        return nil
                                    }
                                    
                                    let accuracy = locationDict["accuracy"] as? Double ?? 0.0
                                    
                                    // 处理client_timestamp字段
                                    var clientTimestamp: Double? = nil
                                    if let clientTimestampObj = locationDict["client_timestamp"] as? [String: Any],
                                       let timestamp = clientTimestampObj["timestamp"] as? Double {
                                        clientTimestamp = timestamp
                                    }
                                    
                                    // 统一使用设备时间
                                    let timestamp = (locationDict["device_time"] as? String) ?? ""
                                    return LocationRecord(
                                        id: objectId.hash, // 使用objectId的hash作为id
                                        objectId: objectId, // 添加 LeanCloud 的 objectId
                                        timestamp: timestamp,
                                        latitude: latitude,
                                        longitude: longitude,
                                        accuracy: accuracy,
                                        user_id: userId,
                                        user_name: locationDict["user_name"] as? String,
                                        login_type: locationDict["login_type"] as? String,
                                        user_email: locationDict["user_email"] as? String, // 添加邮箱字段
                                        user_avatar: locationDict["user_avatar"] as? String, // 添加头像字段
                                        device_id: deviceId,
                                        client_timestamp: clientTimestamp,
                                        timezone: locationDict["timezone"] as? String
                                    )
                                }
                                
                                completion(records, nil)
                            } else {
                                completion([], nil)
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 获取位置记录（排除游客用户、历史记录、当前用户和黑名单用户，优先匹配半小时内2公里内的用户，其余随机匹配）
    func fetchRandomLocation(currentLocation: CLLocationCoordinate2D?, currentUserId: String?, excludeHistory: [LocationRecord] = [], completion: @escaping (LocationRecord?, String?) -> Void) {
        // 先获取黑名单，然后进行匹配
        fetchBlacklist { blacklistedDeviceIds, _ in
            
            let blacklistedIds = blacklistedDeviceIds ?? []
            if !blacklistedIds.isEmpty {
            }
            
            self.fetchLocations { records, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                if let records = records, !records.isEmpty {
                    // 过滤掉游客用户，只保留 Apple ID 用户
                    let appleUsers = records.filter { record in
                        record.login_type != "guest"
                    }
                
                // 过滤掉当前用户自己的记录和黑名单用户
                let otherUsers = appleUsers.filter { record in
                    // 排除当前用户
                    if let currentUserId = currentUserId {
                        if record.user_id == currentUserId {
                            return false
                        }
                    }
                    
                    // 排除黑名单设备和用户
                    if blacklistedIds.contains(record.device_id) || blacklistedIds.contains(record.user_id) {
                        return false
                    }
                    
                    return true
                }
                
                // 过滤掉已经匹配过的用户ID（无论时间差）
                let availableRecords = otherUsers.filter { record in
                    // 检查是否已经匹配过相同用户ID
                    let hasMatchedUser = excludeHistory.contains { historyRecord in
                        historyRecord.user_id == record.user_id
                    }
                    
                    if hasMatchedUser {
                        return false // 排除该记录
                    }
                    
                    return true // 没有匹配过该用户，允许匹配
                }
                
                // 确保每个用户只保留最新的一条记录 - 统一使用设备时间
                var latestRecordsByUser: [String: LocationRecord] = [:]
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                for record in availableRecords {
                    var recordTime: Date?
                    
                    // 尝试解析设备时间 - 支持多种格式
                    if !record.timestamp.isEmpty {
                        // 首先尝试ISO 8601格式
                        recordTime = isoFormatter.date(from: record.timestamp)
                        
                        // 如果ISO格式失败，尝试旧的本地时间格式
                        if recordTime == nil {
                            let localFormatter = DateFormatter()
                            localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            localFormatter.timeZone = nil
                            recordTime = localFormatter.date(from: record.timestamp)
                        }
                    }
                    
                    // 如果设备时间解析失败，使用当前时间作为默认值
                    if recordTime == nil {
                        recordTime = Date()
                    }
                    
                    if let recordTime = recordTime {
                        if let existingRecord = latestRecordsByUser[record.user_id] {
                            var existingTime: Date?
                            
                            // 尝试解析现有记录的ISO格式时间
                            if !existingRecord.timestamp.isEmpty {
                                existingTime = isoFormatter.date(from: existingRecord.timestamp)
                                
                                // 如果ISO格式失败，尝试旧的本地时间格式
                                if existingTime == nil {
                                    let localFormatter = DateFormatter()
                                    localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                    localFormatter.timeZone = nil
                                    existingTime = localFormatter.date(from: existingRecord.timestamp)
                                }
                            }
                            
                            if let existingTime = existingTime {
                                // 如果当前记录更新，则替换
                                if recordTime > existingTime {
                                    latestRecordsByUser[record.user_id] = record
                                }
                            } else {
                                // 如果现有记录时间解析失败，使用当前记录
                                latestRecordsByUser[record.user_id] = record
                            }
                        } else {
                            // 第一次遇到该用户，直接添加
                            latestRecordsByUser[record.user_id] = record
                        }
                    }
                }
                
                // 转换为数组，只包含每个用户的最新记录
                let latestRecords = Array(latestRecordsByUser.values)
                
                // 输出时间处理信息
                for (_, _) in latestRecords.prefix(3).enumerated() {
                }
                
                if !latestRecords.isEmpty {
                    // 如果有当前用户位置，按新的匹配规则进行匹配
                    if let currentLocation = currentLocation {
                        // 计算每个记录的距离和时间（考虑时区）
                        let recordsWithInfo = latestRecords.map { record -> (LocationRecord, Double, Double) in
                            // 计算距离（米）
                            let recordLocation = CLLocation(latitude: record.latitude, longitude: record.longitude)
                            let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
                            let distance = recordLocation.distance(from: userLocation)
                            
                            // 计算考虑时区的实际时间差（分钟）
                            let now = Date()
                            var recordTime: Date?
                            
                            // 尝试解析设备时间 - 支持多种格式
                            if !record.timestamp.isEmpty {
                                // 首先尝试ISO 8601格式
                                recordTime = isoFormatter.date(from: record.timestamp)
                                
                                // 如果ISO格式失败，尝试旧的本地时间格式
                                if recordTime == nil {
                                    let localFormatter = DateFormatter()
                                    localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                    localFormatter.timeZone = nil
                                    recordTime = localFormatter.date(from: record.timestamp)
                                }
                            }
                            
                            // 如果设备时间解析失败，使用当前时间（时间差为0）
                            if recordTime == nil {
                                recordTime = now
                            }
                            
                            // 计算考虑时区的实际时间差
                            let timeDifference = self.calculateTimeDifferenceWithTimezone(
                                recordTime: recordTime!,
                                recordLongitude: record.longitude,
                                currentLongitude: currentLocation.longitude,
                                currentTime: now
                            )
                            
                            return (record, distance, timeDifference)
                        }
                        
                        // 分离不同优先级的匹配用户
                        let priorityRecords = recordsWithInfo.filter { _, distance, timeDifference in
                            // 第一优先级：半小时以内且距离在两公里内
                            return timeDifference <= 30 && distance <= 2000
                        }
                        
                        let secondaryRecords = recordsWithInfo.filter { _, distance, timeDifference in
                            // 第二优先级：半小时以内或距离在两公里内（不要求同时满足）
                            return (timeDifference <= 30 || distance <= 2000) && !(timeDifference <= 30 && distance <= 2000)
                        }
                        
                        let randomRecords = recordsWithInfo.filter { _, distance, timeDifference in
                            // 随机匹配：超过半小时且距离超过两公里
                            return timeDifference > 30 && distance > 2000
                        }
                        
                        // 选择匹配策略
                        let selectedRecord: LocationRecord
                        
                        if !priorityRecords.isEmpty {
                            // 第一优先级：半小时以内且距离在两公里内
                            let randomIndex = Int.random(in: 0..<priorityRecords.count)
                            selectedRecord = priorityRecords[randomIndex].0
                            _ = priorityRecords[randomIndex].1
                            _ = priorityRecords[randomIndex].2
                        } else if !secondaryRecords.isEmpty {
                            // 第二优先级：半小时以内或距离在两公里内
                            let randomIndex = Int.random(in: 0..<secondaryRecords.count)
                            selectedRecord = secondaryRecords[randomIndex].0
                            _ = secondaryRecords[randomIndex].1
                            _ = secondaryRecords[randomIndex].2
                        } else if !randomRecords.isEmpty {
                            // 第三优先级：超过半小时且距离超过两公里
                            let randomIndex = Int.random(in: 0..<randomRecords.count)
                            selectedRecord = randomRecords[randomIndex].0
                            _ = randomRecords[randomIndex].1
                            _ = randomRecords[randomIndex].2
                        } else {
                            // 没有可用记录（理论上不会发生，因为latestRecords不为空）
                            completion(nil, "没有可用的匹配记录")
                            return
                        }
                        
                        completion(selectedRecord, nil)
                    } else {
                        // 没有当前位置时，使用随机选择
                        let randomIndex = Int.random(in: 0..<latestRecords.count)
                        let randomRecord = latestRecords[randomIndex]
                        completion(randomRecord, nil)
                    }
                } else {
                    let totalExcluded = appleUsers.count - latestRecords.count
                    let selfExcluded = appleUsers.count - otherUsers.count
                    let historyExcluded = otherUsers.count - availableRecords.count
                    _ = blacklistedIds.count // 黑名单排除数量
                    
                    // 详细打印匹配失败的原因
                    
                    if !appleUsers.isEmpty {
                        for (_, _) in appleUsers.prefix(10).enumerated() {
                        }
                        if appleUsers.count > 10 {
                        }
                    }
                    
                    if !blacklistedIds.isEmpty {
                        for (_, _) in blacklistedIds.enumerated() {
                        }
                    }
                    
                    if !excludeHistory.isEmpty {
                        for (_, _) in excludeHistory.enumerated() {
                        }
                    }
                    
                    if totalExcluded > 0 {
                        var message = "没有可用的新记录"
                        var details: [String] = []
                        
                        if selfExcluded > 0 {
                            details.append("\(selfExcluded) 条自己的记录")
                        }
                        if blacklistedIds.count > 0 {
                            details.append("\(blacklistedIds.count) 个黑名单用户")
                        }
                        if historyExcluded > 0 {
                            details.append("\(historyExcluded) 条历史记录（包含位置重复和1小时内用户ID重复）")
                        }
                        
                        if !details.isEmpty {
                            message += "（已排除 " + details.joined(separator: "，") + "）"
                        }
                        
                        completion(nil, message)
                } else {
                    if !records.isEmpty {
                        for (_, _) in records.prefix(10).enumerated() {
                        }
                        if records.count > 10 {
                        }
                    }
                    completion(nil, "没有可用的 Apple ID 用户记录")
                    }
                }
            } else {
                completion(nil, "没有可用的位置记录")
            }
        }
        }
    }
    
    // 清除所有位置记录
    func clearAllLocations(completion: @escaping (Bool, String) -> Void) {
        fetchLocations { records, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            if let records = records, !records.isEmpty {
                let group = DispatchGroup()
                var successCount = 0
                var failureCount = 0
                
                for record in records {
                    group.enter()
                    self.deleteLocation(objectId: record.objectId) { success, _ in
                        if success {
                            successCount += 1
                        } else {
                            failureCount += 1
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    if failureCount == 0 {
                        completion(true, "成功清除 \(successCount) 条记录")
                    } else {
                        completion(false, "清除完成，成功 \(successCount) 条，失败 \(failureCount) 条")
                    }
                }
            } else {
                completion(true, "没有需要清除的记录")
            }
        }
    }
    
    // MARK: - 钻石相关方法
    
    // 获取用户头像
    func fetchUserAvatar(userId: String, loginType: String, completion: @escaping (String?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/UserAvatarRecord?where={\"user_id\":\"\(userId)\",\"login_type\":\"\(loginType)\"}&order=-createdAt&limit=1"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]], let firstResult = results.first {
                                if let userAvatar = firstResult["user_avatar"] as? String {
                                    completion(userAvatar, nil)
                                } else {
                                    completion(nil, "头像数据格式错误")
                                }
                            } else {
                                completion(nil, "未找到用户的头像记录")
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 创建用户头像记录
    func createUserAvatarRecord(userId: String, loginType: String, userAvatar: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/UserAvatarRecord"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        // 获取设备ID
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        
        // 获取用户名（从UserDefaults或使用默认值）
        let userName = UserDefaults.standard.string(forKey: "current_user_name") ?? "未知用户"
        
        // 获取邮箱（从UserDefaults或使用默认值）
        let userEmail = UserDefaults.standard.string(forKey: "current_user_email") ?? ""
        
        let data: [String: Any] = [
            "user_id": userId,
            "login_type": loginType,
            "user_name": userName,
            "user_email": userEmail,
            "user_avatar": userAvatar,
            "device_id": deviceID,
            "device_time": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 创建头像记录失败: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        print("✅ 头像记录创建成功")
                        completion(true)
                    } else {
                        print("❌ 创建头像记录失败，状态码: \(httpResponse.statusCode)")
                        completion(false)
                    }
                } else {
                    print("❌ 创建头像记录失败，无效响应")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 更新用户头像记录
    func updateUserAvatarRecord(userId: String, loginType: String, userAvatar: String, completion: @escaping (Bool) -> Void) {
        // 先查找现有的头像记录
        let urlString = "\(serverUrl)/1.1/classes/UserAvatarRecord?where={\"user_id\":\"\(userId)\",\"login_type\":\"\(loginType)\"}&order=-createdAt&limit=1"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 查找头像记录失败: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]], let firstResult = results.first {
                                if let objectId = firstResult["objectId"] as? String {
                                    // 找到现有记录，更新它
                                    self.updateExistingAvatarRecord(objectId: objectId, userAvatar: userAvatar, completion: completion)
                                } else {
                                    // 没有找到记录，创建新记录
                                    self.createUserAvatarRecord(userId: userId, loginType: loginType, userAvatar: userAvatar, completion: completion)
                                }
                            } else {
                                // 没有找到记录，创建新记录
                                self.createUserAvatarRecord(userId: userId, loginType: loginType, userAvatar: userAvatar, completion: completion)
                            }
                        } catch {
                            print("❌ 解析头像记录失败: \(error.localizedDescription)")
                            completion(false)
                        }
                    } else {
                        print("❌ 查找头像记录失败，状态码: \(httpResponse.statusCode)")
                        completion(false)
                    }
                } else {
                    print("❌ 查找头像记录失败，无效响应")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 更新现有的头像记录
    private func updateExistingAvatarRecord(objectId: String, userAvatar: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/UserAvatarRecord/\(objectId)"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        let data: [String: Any] = [
            "user_avatar": userAvatar,
            "device_time": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 更新头像记录失败: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ 头像记录更新成功")
                        completion(true)
                    } else {
                        print("❌ 更新头像记录失败，状态码: \(httpResponse.statusCode)")
                        completion(false)
                    }
                } else {
                    print("❌ 更新头像记录失败，无效响应")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 获取用户钻石数量
    func fetchDiamonds(userId: String, loginType: String, completion: @escaping (Int?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord?where={\"user_id\":\"\(userId)\",\"login_type\":\"\(loginType)\"}&order=-createdAt&limit=1"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]], let firstResult = results.first {
                                if let diamonds = firstResult["diamonds"] as? Int {
                                    // 打印设备ID信息（如果存在）
                                    _ = firstResult["device_id"] as? String
                                    completion(diamonds, nil)
                                } else {
                                    completion(nil, "钻石数据格式错误")
                                }
                            } else {
                                completion(nil, "未找到用户的钻石记录")
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 创建钻石记录
    func createDiamondRecord(userId: String, loginType: String, diamonds: Int, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        // 获取设备ID
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        
        // 获取用户名（从UserDefaults或使用默认值）
        let userName = UserDefaults.standard.string(forKey: "current_user_name") ?? "未知用户"
        
        // 获取邮箱（从UserDefaults或使用默认值）
        let userEmail = UserDefaults.standard.string(forKey: "current_user_email") ?? ""
        
        // 获取用户头像信息
        let userAvatar: String
        if let customEmoji = UserDefaults.standard.string(forKey: "custom_avatar_\(userId)") {
            userAvatar = customEmoji
        } else {
            // 根据用户类型设置默认头像
            switch loginType {
            case "apple":
                userAvatar = "🍎" // Apple logo emoji
            case "internal":
                userAvatar = "👤" // 内部用户 emoji
            case "guest":
                userAvatar = "👥" // 游客 emoji
            default:
                userAvatar = "👤" // 默认 emoji
            }
        }
        
        let diamondData: [String: Any] = [
            "user_id": userId,
            "user_name": userName, // 用户名
            "user_email": userEmail, // 新增邮箱
            "user_avatar": userAvatar, // 添加用户头像
            "login_type": loginType,
            "device_id": deviceID, // 设备ID
            "diamonds": diamonds
        ]
        
        // 为钻石数据添加ACL权限
        let diamondDataWithACL = addACLToData(diamondData)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: diamondDataWithACL)
        } catch {
            completion(false)
            return
        }
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let _ = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 201 {
                        completion(true)
                    } else if httpResponse.statusCode == 403 {
                        // 检查是否是字段权限错误
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    if error.contains("Forbidden to add new fields") {
                                        // 字段创建失败，使用简化数据重试
                                        print("⚠️ 无法创建新字段，使用简化数据重试...")
                                        self.createDiamondRecordWithSimplifiedData(userId: userId, loginType: loginType, diamonds: diamonds, completion: completion)
                                        return
                                    }
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        completion(false)
                    } else {
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    _ = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                _ = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 创建DiamondRecord字段
    private func createDiamondRecordFields(completion: @escaping (Bool) -> Void) {
        print("🔧 尝试创建DiamondRecord字段...")
        
        // 创建一个测试记录来初始化字段
        let testData: [String: Any] = [
            "user_id": "field_init",
            "user_name": "Field Initialization",
            "user_email": "",
            "user_avatar": "👤",
            "login_type": "guest",
            "device_id": "field_init_device",
            "diamonds": 0
        ]
        
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request, contentType: "application/json")
        request.timeoutInterval = 10.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testData)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ DiamondRecord字段创建失败: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        print("✅ DiamondRecord字段创建成功")
                        completion(true)
                    } else {
                        print("❌ DiamondRecord字段创建失败，状态码: \(httpResponse.statusCode)")
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 使用简化数据创建钻石记录（不包含新字段）
    private func createDiamondRecordWithSimplifiedData(userId: String, loginType: String, diamonds: Int, completion: @escaping (Bool) -> Void) {
        print("📤 使用简化数据创建钻石记录...")
        
        // 获取设备ID
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        
        // 获取用户名（从UserDefaults或使用默认值）
        let userName = UserDefaults.standard.string(forKey: "current_user_name") ?? "未知用户"
        
        // 使用简化数据，不包含新字段
        let simplifiedDiamondData: [String: Any] = [
            "user_id": userId,
            "user_name": userName,
            "login_type": loginType,
            "device_id": deviceID,
            "diamonds": diamonds
        ]
        
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request, contentType: "application/json")
        request.timeoutInterval = 10.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: simplifiedDiamondData)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let _ = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        print("✅ 简化钻石记录创建成功")
                        completion(true)
                    } else {
                        print("❌ 简化钻石记录创建失败，状态码: \(httpResponse.statusCode)")
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 更新钻石数量
    func updateDiamonds(userId: String, loginType: String, diamonds: Int, completion: @escaping (Bool) -> Void) {
        // 直接创建新记录，忽略旧记录
        self.createDiamondRecord(userId: userId, loginType: loginType, diamonds: diamonds, completion: completion)
    }
    
    // 获取完整的钻石记录（包括设备ID）
    func fetchDiamondRecords(userId: String, loginType: String, completion: @escaping ([DiamondRecord]?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord?where={\"user_id\":\"\(userId)\",\"login_type\":\"\(loginType)\"}&order=-createdAt&limit=100"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]] {
                                let records = results.compactMap { diamondDict -> DiamondRecord? in
                                    guard let objectId = diamondDict["objectId"] as? String,
                                          let createdAt = diamondDict["createdAt"] as? String,
                                          let updatedAt = diamondDict["updatedAt"] as? String,
                                          let userId = diamondDict["user_id"] as? String,
                                          let loginType = diamondDict["login_type"] as? String,
                                          let diamonds = diamondDict["diamonds"] as? Int else {
                                        return nil
                                    }
                                    
                                    let deviceId = diamondDict["device_id"] as? String
                                    let userName = diamondDict["user_name"] as? String
                                    let userEmail = diamondDict["user_email"] as? String
                                    
                                    return DiamondRecord(
                                        id: objectId.hash,
                                        objectId: objectId,
                                        user_id: userId,
                                        user_name: userName,
                                        user_email: userEmail,
                                        login_type: loginType,
                                        device_id: deviceId,
                                        diamonds: diamonds,
                                        created_at: createdAt,
                                        updated_at: updatedAt
                                    )
                                }
                                
                                completion(records, nil)
                            } else {
                                completion([], nil)
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 更新现有的钻石记录
    private func updateExistingDiamondRecord(userId: String, loginType: String, diamonds: Int, completion: @escaping (Bool) -> Void) {
        // 首先获取记录的objectId
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord?where={\"user_id\":\"\(userId)\",\"login_type\":\"\(loginType)\"}&limit=1"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let _ = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        if let results = json?["results"] as? [[String: Any]], let firstResult = results.first,
                           let objectId = firstResult["objectId"] as? String {
                            // 找到记录，执行更新
                            self.performDiamondUpdate(objectId: objectId, diamonds: diamonds, completion: completion)
                        } else {
                            // 记录不存在，创建新记录
                            self.createDiamondRecord(userId: userId, loginType: loginType, diamonds: diamonds, completion: completion)
                        }
                    } catch {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 删除并重新创建钻石记录
    private func deleteAndRecreateDiamondRecord(userId: String, loginType: String, diamonds: Int, completion: @escaping (Bool) -> Void) {
        // 首先获取记录的objectId
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord?where={\"user_id\":\"\(userId)\",\"login_type\":\"\(loginType)\"}&limit=1"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let _ = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        if let results = json?["results"] as? [[String: Any]], let firstResult = results.first,
                           let objectId = firstResult["objectId"] as? String {
                            // 找到记录，先删除它
                            self.deleteDiamondRecord(objectId: objectId) { success in
                                if success {
                                    // 删除成功后创建新记录
                                    self.createDiamondRecord(userId: userId, loginType: loginType, diamonds: diamonds, completion: completion)
                                } else {
                                    // 删除失败，直接创建新记录
                                    self.createDiamondRecord(userId: userId, loginType: loginType, diamonds: diamonds, completion: completion)
                                }
                            }
                        } else {
                            completion(false)
                        }
                    } catch {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 删除钻石记录
    private func deleteDiamondRecord(objectId: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord/\(objectId)"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let _ = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200 {
                        completion(true)
                    } else {
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    _ = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                _ = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 执行钻石更新
    private func performDiamondUpdate(objectId: String, diamonds: Int, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/DiamondRecord/\(objectId)"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        let updateData: [String: Any] = [
            "diamonds": diamonds
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updateData)
        } catch {
            completion(false)
            return
        }
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let _ = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200 {
                        completion(true)
                    } else {
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    _ = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                _ = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        
                        // 如果是403错误（ACL权限问题），返回false以触发删除并重新创建
                        if httpResponse.statusCode == 403 {
                        }
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    private func deleteLocation(objectId: String, completion: @escaping (Bool, String) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/LocationRecord/\(objectId)"
        guard let url = URL(string: urlString) else {
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "连接失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, "删除成功")
                    } else {
                        let errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        completion(false, errorMessage)
                    }
                } else {
                    completion(false, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 上传举报记录到LeanCloud
    func uploadReportRecord(reportData: [String: Any], completion: @escaping (Bool, String) -> Void) {
        print("📋 开始上传举报记录到LeanCloud...")
        print("   📄 举报数据: \(reportData)")
        print("   📄 reported_user_login_type: \(reportData["reported_user_login_type"] ?? "未找到")")
        print("📤 开始上传举报记录...")
        print("   📋 举报数据: \(reportData)")
        
        // 检查是否包含用户类型字段
        let hasLoginType = reportData["reported_user_login_type"] != nil
        print("   📄 是否包含用户类型字段: \(hasLoginType)")
        
        let urlString = "\(serverUrl)/1.1/classes/ReportRecord"
        print("   🌐 请求URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            print("   ❌ URL格式错误")
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        // 为举报数据添加ACL权限
        let reportDataWithACL = addACLToData(reportData)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: reportDataWithACL)
            print("   📄 请求体大小: \(request.httpBody?.count ?? 0) bytes")
            print("   📄 请求体内容: \(String(data: request.httpBody!, encoding: .utf8) ?? "无法编码")")
        } catch {
            print("   ❌ 数据编码失败: \(error.localizedDescription)")
            completion(false, "数据编码失败: \(error.localizedDescription)")
            return
        }
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("   ❌ 网络错误: \(error.localizedDescription)")
                    completion(false, "上传失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("   📊 HTTP状态码: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 201 {
                        // 成功创建举报记录
                        print("   ✅ 举报记录上传成功")
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let objectId = json?["objectId"] as? String {
                                    print("   📋 记录ID: \(objectId)")
                                }
                                completion(true, "")
                            } catch {
                                print("   ⚠️ 响应解析失败，但上传成功")
                                completion(true, "")
                            }
                        } else {
                            print("   ⚠️ 无响应数据，但上传成功")
                            completion(true, "")
                        }
                    } else if httpResponse.statusCode == 403 {
                        // 检查是否是字段权限错误
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    if error.contains("Forbidden to add new fields") {
                                        // 字段创建失败，使用简化数据重试
                                        print("⚠️ 无法创建新字段，使用简化数据重试...")
                                        self.uploadReportRecordWithSimplifiedData(reportData: reportData, completion: completion)
                                        return
                                    }
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        
                        // 如果不是字段权限错误，按原来的方式处理
                        print("   ❌ 举报记录上传失败")
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            print("   📄 错误响应数据大小: \(data.count) bytes")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("   📄 错误响应内容: \(responseString)")
                            }
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                    print("   📋 LeanCloud错误: \(error)")
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                                print("   📋 服务器错误: \(httpResponse.statusCode)")
                            }
                        }
                        completion(false, errorMessage)
                    } else {
                        // 处理其他错误响应
                        print("   ❌ 举报记录上传失败")
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            print("   📄 错误响应数据大小: \(data.count) bytes")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("   📄 错误响应内容: \(responseString)")
                            }
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                    print("   📋 LeanCloud错误: \(error)")
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                                print("   📋 服务器错误: \(httpResponse.statusCode)")
                            }
                        }
                        completion(false, errorMessage)
                    }
                } else {
                    completion(false, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 创建ReportRecord字段
    private func createReportRecordFields(completion: @escaping (Bool) -> Void) {
        print("🔧 尝试创建ReportRecord字段...")
        
        // 创建一个测试记录来初始化字段
        let testData: [String: Any] = [
            "reported_user_id": "field_init_device",
            "reported_user_name": "Field Initialization",
            "reported_user_email": "",
            "reported_user_login_type": "guest",
            "report_reason": "Field initialization",
            "report_time": ISO8601DateFormatter().string(from: Date()),
            "reporter_user_id": "field_init",
            "reporter_user_name": "Field Initialization",
            "reporter_user_avatar": "👤"
        ]
        
        let urlString = "\(serverUrl)/1.1/classes/ReportRecord"
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request, contentType: "application/json")
        request.timeoutInterval = 10.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testData)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ ReportRecord字段创建失败: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        print("✅ ReportRecord字段创建成功")
                        completion(true)
                    } else {
                        print("❌ ReportRecord字段创建失败，状态码: \(httpResponse.statusCode)")
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 使用简化数据上传举报记录（不包含新字段）
    private func uploadReportRecordWithSimplifiedData(reportData: [String: Any], completion: @escaping (Bool, String) -> Void) {
        print("📤 使用简化数据上传举报记录...")
        
        // 提取基本字段，不包含新添加的字段
        let simplifiedReportData: [String: Any] = [
            "reported_user_id": reportData["reported_user_id"] ?? "",
            "reported_user_name": reportData["reported_user_name"] ?? "",
            "reported_user_email": reportData["reported_user_email"] ?? "",
            "reported_user_login_type": reportData["reported_user_login_type"] ?? "",
            "report_reason": reportData["report_reason"] ?? "",
            "report_time": reportData["report_time"] ?? "",
            "reporter_user_id": reportData["reporter_user_id"] ?? "",
            "reporter_user_name": reportData["reporter_user_name"] ?? ""
        ]
        
        let urlString = "\(serverUrl)/1.1/classes/ReportRecord"
        guard let url = URL(string: urlString) else {
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request, contentType: "application/json")
        request.timeoutInterval = 10.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: simplifiedReportData)
        } catch {
            completion(false, "数据编码失败: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "上传失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        print("✅ 简化举报记录上传成功")
                        completion(true, "")
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                // 忽略JSON解析错误
                            }
                        }
                        completion(false, errorMessage)
                    }
                } else {
                    completion(false, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 从LeanCloud获取举报记录
    func fetchReportRecords(completion: @escaping ([ReportRecord]?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/ReportRecord?order=-createdAt&limit=1000"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]] {
                                let records = results.compactMap { reportDict -> ReportRecord? in
                                    guard let reportedUserId = reportDict["reported_user_id"] as? String,
                                          let reportReason = reportDict["report_reason"] as? String,
                                          let reporterUserId = reportDict["reporter_user_id"] as? String else {
                                        return nil
                                    }
                                    
                                    // 时间解析暂时未使用
                                    
                                    return ReportRecord(
                                        reportedUserId: reportedUserId,
                                        reportedUserName: reportDict["reported_user_name"] as? String,
                                        reportedUserEmail: reportDict["reported_user_email"] as? String,
                                        reportedUserAvatar: reportDict["reported_user_avatar"] as? String,
                                        reportedUserLoginType: reportDict["reported_user_login_type"] as? String,
                                        reportReason: reportReason,
                                        reporterUserId: reporterUserId,
                                        reporterUserName: reportDict["reporter_user_name"] as? String,
                                        reporterUserAvatar: reportDict["reporter_user_avatar"] as? String,
                                        status: reportDict["status"] as? String,
                                        objectId: reportDict["objectId"] as? String
                                    )
                                }
                                
                                completion(records, nil)
                            } else {
                                completion([], nil)
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // MARK: - 黑名单相关方法
    
    // 从LeanCloud获取黑名单ID列表（包括设备ID和用户ID）
    func fetchBlacklist(completion: @escaping ([String]?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/Blacklist?order=-createdAt&limit=1000"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            
                            if let results = json?["results"] as? [[String: Any]] {
                                
                                // 打印第一条记录的字段信息
                                _ = results.first
                                
                                var blacklistedIds: [String] = []
                                
                                for blacklistDict in results {
                                    // 检查是否已过期
                                    var isExpired = false
                                    if let expiresAtDict = blacklistDict["expires_at"] as? [String: Any],
                                       let expiresAtString = expiresAtDict["iso"] as? String {
                                        let formatter = ISO8601DateFormatter()
                                        if let expiresAt = formatter.date(from: expiresAtString) {
                                            let now = Date()
                                            if now > expiresAt {
                                                isExpired = true
                                            }
                                        }
                                    }
                                    
                                    if !isExpired {
                                        // 添加设备ID
                                        if let deviceId = blacklistDict["device_id"] as? String {
                                            blacklistedIds.append(deviceId)
                                        }
                                        
                                        // 添加用户名
                                        if let reportedUserName = blacklistDict["reported_user_name"] as? String {
                                            blacklistedIds.append(reportedUserName)
                                        }
                                    }
                                }
                                
                                if !blacklistedIds.isEmpty {
                                }
                                completion(blacklistedIds, nil)
                            } else {
                                completion([], nil)
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 从LeanCloud获取黑名单用户ID列表
    func fetchUserBlacklist(completion: @escaping ([String]?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/Blacklist?order=-createdAt&limit=1000"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            
                            if let results = json?["results"] as? [[String: Any]] {
                                
                                let blacklistedUserIds = results.compactMap { blacklistDict -> String? in
                                    // 检查是否有reported_user_id字段（存储的是设备ID）
                                    guard let deviceId = blacklistDict["reported_user_id"] as? String else {
                                        return nil
                                    }
                                    
                                    // 检查是否已过期
                                    if let expiresAtDict = blacklistDict["expires_at"] as? [String: Any],
                                       let expiresAtString = expiresAtDict["iso"] as? String {
                                        let formatter = ISO8601DateFormatter()
                                        if let expiresAt = formatter.date(from: expiresAtString) {
                                            let now = Date()
                                            if now > expiresAt {
                                                return nil
                                            }
                                        }
                                    }
                                    
                                    return deviceId
                                }
                                
                                completion(blacklistedUserIds, nil)
                            } else {
                                completion([], nil)
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 获取指定设备的黑名单过期时间
    func fetchDeviceBlacklistExpiryTime(deviceId: String, completion: @escaping (Date?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/Blacklist?where={\"reported_user_id\":\"\(deviceId)\"}&order=-createdAt&limit=1"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "网络错误: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]], !results.isEmpty {
                                let record = results[0]
                                if let expiresAtDict = record["expires_at"] as? [String: Any],
                                   let expiresAtString = expiresAtDict["iso"] as? String {
                                    
                                    // 使用ISO8601DateFormatter解析
                                    let formatter = ISO8601DateFormatter()
                                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                    
                                    if let expiryTime = formatter.date(from: expiresAtString) {
                                        completion(expiryTime, nil)
                                    } else {
                                        // 如果ISO8601解析失败，尝试其他格式
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                                        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                                        
                                        if let expiryTime = dateFormatter.date(from: expiresAtString) {
                                            completion(expiryTime, nil)
                                        } else {
                                            completion(nil, "无法解析过期时间")
                                        }
                                    }
                                } else {
                                    completion(nil, "记录中没有过期时间字段")
                                }
                            } else {
                                completion(nil, "未找到设备的黑名单记录")
                            }
                        } catch {
                            completion(nil, "解析响应失败: \(error.localizedDescription)")
                        }
                    } else {
                        completion(nil, "服务器错误: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(nil, "无效的响应")
                }
            }
        }.resume()
    }
    
    // 获取指定用户/设备的黑名单过期时间
    func fetchUserBlacklistExpiryTime(userId: String, completion: @escaping (Date?, String?) -> Void) {
        print("🔍 查询用户黑名单记录: \(userId)")
        let urlString = "\(serverUrl)/1.1/classes/Blacklist?where={\"reported_user_name\":\"\(userId)\"}&order=-createdAt&limit=1"
        print("🌐 请求URL: \(urlString)")
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "网络错误: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]], !results.isEmpty {
                                let record = results[0]
                                if let expiresAtDict = record["expires_at"] as? [String: Any],
                                   let expiresAtString = expiresAtDict["iso"] as? String {
                                    
                                    // 使用ISO8601DateFormatter解析
                                    let formatter = ISO8601DateFormatter()
                                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                                    
                                    if let expiryTime = formatter.date(from: expiresAtString) {
                                        completion(expiryTime, nil)
                                    } else {
                                        // 如果ISO8601解析失败，尝试其他格式
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                                        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
                                        
                                        if let expiryTime = dateFormatter.date(from: expiresAtString) {
                                            completion(expiryTime, nil)
                                        } else {
                                            completion(nil, "无法解析过期时间")
                                        }
                                    }
                                } else {
                                    print("⚠️ 记录中没有过期时间字段")
                                    completion(nil, "记录中没有过期时间字段")
                                }
                            } else {
                                print("⚠️ 未找到用户的黑名单记录")
                                completion(nil, "未找到用户的黑名单记录")
                            }
                        } catch {
                            completion(nil, "解析响应失败: \(error.localizedDescription)")
                        }
                    } else {
                        completion(nil, "服务器错误: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(nil, "无效的响应")
                }
            }
        }.resume()
    }
    
    // MARK: - 内部账号验证方法
    
    // 验证内部账号登录 - 使用LeanCloud _User表
    func verifyInternalAccount(username: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        print("🔐 开始验证内部账号登录...")
        print("   📋 用户名: \(username)")
        print("   🔑 密码: \(String(repeating: "*", count: password.count))")
        
        // 使用LeanCloud的登录API
        let urlString = "\(serverUrl)/1.1/login"
        print("   🌐 请求URL: \(urlString)")
        
                                guard let url = URL(string: urlString) else {
                            print("   ❌ URL格式错误")
                            completion(false, "服务器地址无效")
                            return
                        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        // 构建登录数据
        let loginData: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData)
            print("   📄 登录数据: \(loginData)")
        } catch {
            print("   ❌ 数据编码失败: \(error.localizedDescription)")
            completion(false, "数据格式错误，请重试")
            return
        }
        
        print("   📋 请求方法: \(request.httpMethod ?? "未知")")
        print("   📋 请求头:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("     \(key): \(value)")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("   ❌ 网络错误: \(error.localizedDescription)")
                    completion(false, "网络连接失败，请检查网络设置")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("   📊 HTTP状态码: \(httpResponse.statusCode)")
                    print("   📋 响应头:")
                    for (key, value) in httpResponse.allHeaderFields {
                        print("     \(key): \(value)")
                    }
                    
                    if httpResponse.statusCode == 200, let data = data {
                        print("   📄 响应数据大小: \(data.count) bytes")
                        
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            print("   📄 响应JSON: \(json ?? [:])")
                            
                            // 检查是否包含用户信息
                            if let sessionToken = json?["sessionToken"] as? String,
                               let objectId = json?["objectId"] as? String {
                                print("   ✅ 登录成功")
                                print("   📋 用户ID: \(objectId)")
                                print("   🔑 Session Token: \(sessionToken)")
                                completion(true, nil)
                            } else {
                                print("   ❌ 响应中缺少必要的用户信息")
                                completion(false, "登录验证失败，请检查账号密码")
                            }
                        } catch {
                            print("   ❌ 数据解析失败: \(error.localizedDescription)")
                            completion(false, "服务器响应异常，请重试")
                        }
                    } else {
                        print("   ❌ 服务器错误: \(httpResponse.statusCode)")
                        if let data = data {
                            print("   📄 错误响应数据大小: \(data.count) bytes")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("   📄 错误响应内容: \(responseString)")
                            }
                        }
                        
                        var errorMessage = "服务器连接失败，请稍后重试"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    // 根据LeanCloud的错误类型返回中文提示
                                    if error.contains("Invalid username/password") {
                                        errorMessage = "账号或密码错误"
                                    } else if error.contains("User not found") {
                                        errorMessage = "账号不存在"
                                    } else if error.contains("Too many requests") {
                                        errorMessage = "请求过于频繁，请稍后重试"
                                    } else {
                                        errorMessage = "登录失败，请检查账号密码"
                                    }
                                    print("   📄 LeanCloud错误详情: \(error)")
                                }
                            } catch {
                                print("   ❌ 错误响应JSON解析失败: \(error.localizedDescription)")
                            }
                        }
                        completion(false, errorMessage)
                    }
                } else {
                    print("   ❌ 无效的响应")
                    completion(false, "服务器响应异常，请重试")
                }
            }
        }.resume()
    }
    
    // 创建测试账号（用于管理员创建账号）- 使用LeanCloud _User表
    func createInternalAccount(username: String, password: String, completion: @escaping (Bool, String) -> Void) {
        print("🔐 开始创建测试账号...")
        print("   📋 用户名: \(username)")
        print("   🔑 密码: \(String(repeating: "*", count: password.count))")
        
        // 使用LeanCloud的用户注册API
        let urlString = "\(serverUrl)/1.1/users"
        print("   🌐 请求URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("   ❌ URL格式错误")
            completion(false, "服务器地址无效")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        // 构建用户数据
        let userData: [String: Any] = [
            "username": username,
            "password": password,
            "email": "\(username)@internal.local" // 添加一个内部邮箱
        ]
        
        print("   📄 用户数据: \(userData)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: userData)
            print("   📄 请求体大小: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("   ❌ 数据编码失败: \(error.localizedDescription)")
            completion(false, "数据格式错误，请重试")
            return
        }
        
        print("   📋 请求方法: \(request.httpMethod ?? "未知")")
        print("   📋 请求头:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("     \(key): \(value)")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("   ❌ 网络错误: \(error.localizedDescription)")
                    completion(false, "网络连接失败，请检查网络设置")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("   📊 HTTP状态码: \(httpResponse.statusCode)")
                    print("   📋 响应头:")
                    for (key, value) in httpResponse.allHeaderFields {
                        print("     \(key): \(value)")
                    }
                    
                    if httpResponse.statusCode == 201 {
                        print("   ✅ 账号创建成功")
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let objectId = json?["objectId"] as? String {
                                    print("   📋 用户ID: \(objectId)")
                                }
                            } catch {
                                print("   ⚠️ 无法解析响应中的用户ID")
                            }
                        }
                        completion(true, "测试账号创建成功")
                    } else {
                        print("   ❌ 服务器错误: \(httpResponse.statusCode)")
                        var errorMessage = "服务器连接失败，请稍后重试"
                        
                        if let data = data {
                            print("   📄 错误响应数据大小: \(data.count) bytes")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("   📄 错误响应内容: \(responseString)")
                            }
                            
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    // 根据LeanCloud的错误类型返回中文提示
                                    if error.contains("Username has already been taken") {
                                        errorMessage = "账号已存在，请使用其他账号名"
                                    } else if error.contains("Invalid username") {
                                        errorMessage = "账号名格式不正确"
                                    } else if error.contains("Invalid password") {
                                        errorMessage = "密码格式不正确"
                                    } else if error.contains("Too many requests") {
                                        errorMessage = "请求过于频繁，请稍后重试"
                                    } else {
                                        errorMessage = "创建账号失败，请重试"
                                    }
                                    print("   📄 LeanCloud错误详情: \(error)")
                                }
                            } catch {
                                print("   ❌ 错误响应JSON解析失败: \(error.localizedDescription)")
                                errorMessage = "服务器连接失败，请稍后重试"
                            }
                        }
                        completion(false, errorMessage)
                    }
                } else {
                    print("   ❌ 无效的响应")
                    completion(false, "无效的响应")
                }
            }
        }.resume()
    }
    
    // MARK: - 通用数据读取方法
    
    // 读取LeanCloud中指定表的所有内容
    func fetchAllDataFromTable(tableName: String, completion: @escaping ([[String: Any]]?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/\(tableName)?order=-createdAt&limit=1000"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 15.0
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, "获取失败: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    
                    if httpResponse.statusCode == 200, let data = data {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]] {
                                completion(results, nil)
                            } else {
                                completion([], nil)
                            }
                        } catch {
                            completion(nil, "数据解析失败: \(error.localizedDescription)")
                        }
                    } else {
                        var errorMessage = "服务器错误: \(httpResponse.statusCode)"
                        if let data = data {
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "LeanCloud错误: \(error)"
                                }
                            } catch {
                                errorMessage = "服务器错误: \(httpResponse.statusCode)"
                            }
                        }
                        completion(nil, errorMessage)
                    }
                } else {
                    completion(nil, "无效的服务器响应")
                }
            }
        }.resume()
    }
    
    // 读取LeanCloud中所有表的内容
    func fetchAllDataFromAllTables(completion: @escaping ([String: [[String: Any]]]?, String?) -> Void) {
        let tables = ["LocationRecord", "DiamondRecord", "Blacklist", "ReportRecord", "AccountDeletionRequest"]
        var allData: [String: [[String: Any]]] = [:]
        let group = DispatchGroup()
        var hasError = false
        var errorMessage = ""
        
        
        for tableName in tables {
            group.enter()
            fetchAllDataFromTable(tableName: tableName) { data, error in
                if let error = error {
                    hasError = true
                    errorMessage = "\(tableName) 表读取失败: \(error)"
                } else if let data = data {
                    allData[tableName] = data
                } else {
                    allData[tableName] = []
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if hasError {
                completion(nil, errorMessage)
            } else {
                for (_, _) in allData {
                }
                completion(allData, nil)
            }
        }
    }
    
    // 打印指定表的详细数据
    func printTableData(tableName: String, data: [[String: Any]]) {
        
        for (index, record) in data.enumerated() {
            
            // 按字段名排序，让输出更有序
            let sortedKeys = record.keys.sorted()
            for key in sortedKeys {
                _ = record[key] ?? "nil"
            }
            
            if index < data.count - 1 {
            }
        }
    }
    
    // 打印所有表的汇总信息
    func printAllTablesSummary(allData: [String: [[String: Any]]]) {
        
        var totalRecords = 0
        for (_, data) in allData {
            totalRecords += data.count
            
            if !data.isEmpty {
                // 显示第一条记录的字段
                let firstRecord = data[0]
                _ = Array(firstRecord.keys).sorted()
                
                // 显示一些示例数据
                for (_, _) in firstRecord.prefix(8) {
                }
                if firstRecord.count > 8 {
                }
            } else {
            }
        }
        
    }
    
    // 检查用户是否有待删除的账户请求
    func checkPendingDeletionRequest(userId: String, completion: @escaping (Bool, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/AccountDeletionRequest?where={\"user_id\":\"\(userId)\",\"status\":\"pending\"}&limit=1&order=-createdAt"
        
        guard let url = URL(string: urlString) else {
            completion(false, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, nil)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let data = data {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                        if let results = json?["results"] as? [[String: Any]], !results.isEmpty {
                            let request = results[0]
                            let deletionDate = request["deletion_date"] as? String ?? ""
                            completion(true, deletionDate)
                        } else {
                            completion(false, nil)
                        }
                    } catch {
                        completion(false, nil)
                    }
                } else {
                    completion(false, nil)
                }
            }
        }.resume()
    }
    
    // 取消账户删除请求
    func cancelAccountDeletion(userId: String, completion: @escaping (Bool) -> Void) {
        // 先查找待删除的请求
        let urlString = "\(serverUrl)/1.1/classes/AccountDeletionRequest?where={\"user_id\":\"\(userId)\",\"status\":\"pending\"}&limit=1"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
               let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let results = json?["results"] as? [[String: Any]], !results.isEmpty {
                        let requestId = results[0]["objectId"] as? String
                        if let requestId = requestId {
                            // 删除这个请求
                            self.deleteDeletionRequest(requestId: requestId, completion: completion)
                        } else {
                            completion(false)
                        }
                    } else {
                        completion(false)
                    }
                } catch {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }.resume()
    }
    
    // 删除指定的删除请求
    private func deleteDeletionRequest(requestId: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/AccountDeletionRequest/\(requestId)"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        setLeanCloudHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true)
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 发送账户删除请求
    func requestAccountDeletion(userId: String, userName: String?, deviceId: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/AccountDeletionRequest"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        // 准备删除请求数据
        // 确保包含头像
        let deletionUserAvatar = UserDefaults.standard.string(forKey: "custom_avatar_\(userId)") ?? "👤"
        let deletionData: [String: Any] = [
            "user_id": userId,
            "user_name": userName ?? "未知用户",
            "user_avatar": deletionUserAvatar,
            "device_id": deviceId,
            "request_time": ISO8601DateFormatter().string(from: Date()),
            "status": "pending",
            "deletion_date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(7 * 24 * 3600)) // 7天后
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: deletionData)
        } catch {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 201 {
                        completion(true)
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // 删除用户数据（保留原有方法以备后用）
    func deleteUserData(userId: String, completion: @escaping (Bool) -> Void) {
        let tables = ["LocationRecord", "DiamondRecord", "Blacklist", "ReportRecord"]
        let group = DispatchGroup()
        var successCount = 0
        
        for tableName in tables {
            group.enter()
            deleteUserDataFromTable(tableName: tableName, userId: userId) { success in
                if success {
                    successCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // 如果至少有一个表删除成功，就认为删除成功
            let overallSuccess = successCount > 0
            completion(overallSuccess)
        }
    }
    
    // 从指定表中删除用户数据
    private func deleteUserDataFromTable(tableName: String, userId: String, completion: @escaping (Bool) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/\(tableName)?where={\"user_id\":\"\(userId)\"}"
        
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        setLeanCloudHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true)
                    } else {
                        completion(false)
                    }
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - 连接测试方法
    
    // 测试LeanCloud连接
    func testConnection(completion: @escaping (Bool, String) -> Void) {
        // 验证API密钥
        guard validateApiCredentials() else {
            completion(false, "API配置验证失败")
            return
        }
        
        let testUrl = "\(serverUrl)/1.1/classes/LocationRecord?limit=1"
        guard let url = URL(string: testUrl) else {
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 15.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleNetworkError(error, request, operation: "连接测试")
                    completion(false, "网络错误: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        completion(true, "连接成功")
                    } else if httpResponse.statusCode == 401 {
                        completion(false, "认证失败，请检查App Key")
                    } else if httpResponse.statusCode == 403 {
                        self.handle403Error(httpResponse, data, request, "连接测试")
                        completion(false, "权限不足，请检查ACL配置")
                    } else {
                        completion(false, "服务器错误: \(httpResponse.statusCode)")
                    }
                } else {
                    completion(false, "无效的响应")
                }
            }
        }.resume()
    }
    
    // 诊断连接问题
    func diagnoseConnectionIssues(completion: @escaping ([String]) -> Void) {
        var issues: [String] = []
        
        // 检查配置
        if appId.isEmpty {
            issues.append("App ID为空")
        }
        if appKey.isEmpty {
            issues.append("App Key为空")
        }
        if serverUrl.isEmpty {
            issues.append("Server URL为空")
        }
        if !serverUrl.hasPrefix("https://") {
            issues.append("Server URL不是HTTPS")
        }
        
        // 测试网络连接
        testConnection { success, message in
            if !success {
                issues.append("连接测试失败: \(message)")
            }
            
            DispatchQueue.main.async {
                completion(issues)
            }
        }
    }
    
    // MARK: - 内部账号登录记录
    
    // 上传内部账号登录记录
    func uploadInternalLoginRecord(username: String, deviceId: String, completion: @escaping (Bool, String?) -> Void) {
        print("📝 开始上传内部账号登录记录...")
        print("   👤 用户名: \(username)")
        print("   📱 设备ID: \(deviceId)")
        
        // 使用LeanCloud的创建对象API
        let urlString = "\(serverUrl)/1.1/classes/InternalLoginRecord"
        print("   🌐 请求URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("   ❌ URL格式错误")
            completion(false, "服务器地址无效")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        // 获取用户头像信息（内部用户使用默认头像）
        let userAvatar = "👤" // 内部用户默认头像
        
        // 构建登录记录数据
        let loginRecordData: [String: Any] = [
            "username": username,
            "device_id": deviceId,
            "login_time": ISO8601DateFormatter().string(from: Date()),
            "login_type": "internal",
            "user_avatar": userAvatar // 添加用户头像
        ]
        
        print("   📄 登录记录数据: \(loginRecordData)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginRecordData)
            print("   📄 请求体大小: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("   ❌ 数据编码失败: \(error.localizedDescription)")
            completion(false, "数据格式错误，请重试")
            return
        }
        
        print("   📋 请求方法: \(request.httpMethod ?? "未知")")
        print("   📋 请求头:")
        for (key, value) in request.allHTTPHeaderFields ?? [:] {
            print("     \(key): \(value)")
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("   ❌ 网络错误: \(error.localizedDescription)")
                    completion(false, "网络连接失败，请检查网络设置")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("   📊 HTTP状态码: \(httpResponse.statusCode)")
                    print("   📋 响应头:")
                    for (key, value) in httpResponse.allHeaderFields {
                        print("     \(key): \(value)")
                    }
                    
                    if httpResponse.statusCode == 201 {
                        print("   ✅ 内部账号登录记录上传成功")
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let objectId = json?["objectId"] as? String {
                                    print("   📋 记录ID: \(objectId)")
                                }
                            } catch {
                                print("   ⚠️ 无法解析响应中的记录ID")
                            }
                        }
                        completion(true, nil)
                    } else {
                        print("   ❌ 服务器错误: \(httpResponse.statusCode)")
                        var errorMessage = "服务器连接失败，请稍后重试"
                        
                        if let data = data {
                            print("   📄 错误响应数据大小: \(data.count) bytes")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("   📄 错误响应内容: \(responseString)")
                            }
                            
                            do {
                                let errorJson = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                if let error = errorJson?["error"] as? String {
                                    errorMessage = "上传失败: \(error)"
                                    print("   📄 LeanCloud错误详情: \(error)")
                                }
                                if let code = errorJson?["code"] as? Int {
                                    print("   📄 LeanCloud错误代码: \(code)")
                                }
                            } catch {
                                print("   ❌ 错误响应JSON解析失败: \(error.localizedDescription)")
                            }
                        }
                        completion(false, errorMessage)
                    }
                } else {
                    print("   ❌ 无效的响应")
                    completion(false, "服务器响应异常，请重试")
                }
            }
        }.resume()
    }
    
    // MARK: - 举报记录相关方法
    
    // 举报记录数据模型
    struct LeanCloudReportRecord {
        let id: String
        let reporterUserId: String
        let reporterUserName: String
        let reportedUserId: String
        let reportedUserName: String
        let reportedUserEmail: String
        let reportedUserLoginType: String? // 被举报用户的用户类型
        let reportReason: String
        let reportTime: Date
    }
    
    // 获取举报记录列表
    func fetchReportRecords(completion: @escaping ([LeanCloudReportRecord]?, String?) -> Void) {
        print("📋 开始获取举报记录...")
        let urlString = "\(serverUrl)/1.1/classes/ReportRecord?order=-createdAt&limit=100"
        print("🌐 请求URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 网络错误: \(error.localizedDescription)")
                    completion(nil, "网络错误: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP状态码: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200, let data = data {
                        print("📄 响应数据大小: \(data.count) bytes")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("📄 响应内容: \(responseString)")
                        }
                        
                        do {
                            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                            if let results = json?["results"] as? [[String: Any]] {
                                print("📋 找到 \(results.count) 条举报记录")
                                
                                var reportRecords: [LeanCloudReportRecord] = []
                                for record in results {
                                    if let reportRecord = self.parseReportRecord(from: record) {
                                        reportRecords.append(reportRecord)
                                    }
                                }
                                
                                completion(reportRecords, nil)
                            } else {
                                print("⚠️ 未找到举报记录")
                                completion([], nil)
                            }
                        } catch {
                            print("❌ 解析响应失败: \(error.localizedDescription)")
                            completion(nil, "解析响应失败: \(error.localizedDescription)")
                        }
                    } else {
                        print("❌ 服务器错误: \(httpResponse.statusCode)")
                        completion(nil, "服务器错误: \(httpResponse.statusCode)")
                    }
                } else {
                    print("❌ 无效的响应")
                    completion(nil, "无效的响应")
                }
            }
        }.resume()
    }
    
    // 解析举报记录
    private func parseReportRecord(from record: [String: Any]) -> LeanCloudReportRecord? {
        guard let objectId = record["objectId"] as? String,
              let reporterUserName = record["reporter_user_name"] as? String,
              let reportedUserName = record["reported_user_name"] as? String,
              let reportReason = record["report_reason"] as? String,
              let reportTimeString = record["report_time"] as? String else {
            print("⚠️ 举报记录字段不完整")
            return nil
        }
        
        // 解析举报时间
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let reportTime = formatter.date(from: reportTimeString) ?? Date()
        
        // 获取其他可选字段
        let reporterUserId = record["reporter_user_id"] as? String ?? ""
        let reportedUserId = record["reported_user_id"] as? String ?? ""
        let reportedUserEmail = record["reported_user_email"] as? String ?? ""
        let reportedUserLoginType = record["reported_user_login_type"] as? String
        
        return LeanCloudReportRecord(
            id: objectId,
            reporterUserId: reporterUserId,
            reporterUserName: reporterUserName,
            reportedUserId: reportedUserId,
            reportedUserName: reportedUserName,
            reportedUserEmail: reportedUserEmail,
            reportedUserLoginType: reportedUserLoginType,
            reportReason: reportReason,
            reportTime: reportTime
        )
    }
    
    // 处理举报记录
    func processReportRecord(recordId: String, action: String, completion: @escaping (Bool, String?) -> Void) {
        print("📋 开始处理举报记录: \(recordId), 操作: \(action)")
        
        // 首先获取举报记录的完整内容
        fetchReportRecordDetails(recordId: recordId) { [weak self] recordData, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ 获取举报记录详情失败: \(error)")
                completion(false, "获取举报记录详情失败: \(error)")
                return
            }
            
            guard let recordData = recordData else {
                print("❌ 未找到举报记录")
                completion(false, "未找到举报记录")
                return
            }
            
            // 将举报记录内容加上处理结果上传到新表
            self.uploadProcessedReportRecord(originalRecord: recordData, action: action, completion: completion)
        }
    }
    
    // 获取举报记录详情
    private func fetchReportRecordDetails(recordId: String, completion: @escaping ([String: Any]?, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/ReportRecord/\(recordId)"
        guard let url = URL(string: urlString) else {
            completion(nil, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        setLeanCloudHeaders(&request)
        request.timeoutInterval = 10.0
        
        print("   📋 获取举报记录详情: \(recordId)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 网络错误: \(error.localizedDescription)")
                    completion(nil, "网络错误: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP状态码: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        if let data = data {
                            do {
                                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                                print("✅ 成功获取举报记录详情")
                                completion(json, nil)
                            } catch {
                                print("❌ 解析响应数据失败: \(error)")
                                completion(nil, "解析响应数据失败: \(error)")
                            }
                        } else {
                            print("❌ 无响应数据")
                            completion(nil, "无响应数据")
                        }
                    } else {
                        print("❌ 服务器错误: \(httpResponse.statusCode)")
                        completion(nil, "服务器错误: \(httpResponse.statusCode)")
                    }
                } else {
                    print("❌ 无效的响应")
                    completion(nil, "无效的响应")
                }
            }
        }.resume()
    }
    
    // 上传处理后的举报记录到新表
    private func uploadProcessedReportRecord(originalRecord: [String: Any], action: String, completion: @escaping (Bool, String?) -> Void) {
        let urlString = "\(serverUrl)/1.1/classes/ProcessedReportRecord"
        guard let url = URL(string: urlString) else {
            completion(false, "无效的URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        setLeanCloudHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0
        
        print("   📋 上传处理后的举报记录到新表")
        
        // 构建包含原始记录内容和处理结果的数据
        var processedRecordData: [String: Any] = [:]
        
        // 复制原始记录的所有字段
        for (key, value) in originalRecord {
            if key != "objectId" && key != "createdAt" && key != "updatedAt" && key != "ACL" {
                processedRecordData["original_\(key)"] = value
            }
        }
        
        // 添加处理相关信息 + 处理者头像
        processedRecordData["processing_action"] = action
        processedRecordData["processing_time"] = ISO8601DateFormatter().string(from: Date())
        processedRecordData["processor_device_id"] = UIDevice.current.identifierForVendor?.uuidString ?? "unknown_device"
        if let processorUserId = UserDefaults.standard.string(forKey: "current_user_id") {
            processedRecordData["processor_user_id"] = processorUserId
            processedRecordData["processor_user_avatar"] = UserDefaults.standard.string(forKey: "custom_avatar_\(processorUserId)") ?? "👤"
        }
        
        // 添加ACL权限
        let processedRecordDataWithACL = addACLToData(processedRecordData)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: processedRecordDataWithACL)
            print("📄 处理后的举报记录数据: \(processedRecordData)")
        } catch {
            completion(false, "数据编码失败")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 网络错误: \(error.localizedDescription)")
                    completion(false, "网络错误: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP状态码: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 201 {
                        print("✅ 处理后的举报记录上传成功")
                        completion(true, nil)
                    } else {
                        print("❌ 服务器错误: \(httpResponse.statusCode)")
                        completion(false, "服务器错误: \(httpResponse.statusCode)")
                    }
                } else {
                    print("❌ 无效的响应")
                    completion(false, "无效的响应")
                }
            }
        }.resume()
    }
}
