import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("隐私政策")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("最后更新：2025年1月")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("欢迎使用我们的位置匹配应用。我们非常重视您的隐私保护，本隐私政策详细说明了我们如何收集、使用和保护您的个人信息。")
                        .font(.body)
                    
                    Text("通过使用本应用，您同意我们按照本隐私政策收集和使用您的信息。")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("1. 我们收集的信息")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 位置信息：用于匹配附近的其他用户")
                        .font(.body)
                    Text("• 用户标识：Apple ID 或设备标识符")
                        .font(.body)
                    Text("• 用户资料：昵称、邮箱地址（可选）")
                        .font(.body)
                    Text("• 设备信息：设备型号、操作系统版本")
                        .font(.body)
                    Text("• 使用数据：应用使用统计、匹配记录")
                        .font(.body)
                    
                    Text("2. 信息使用目的")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 提供位置匹配服务")
                        .font(.body)
                    Text("• 改善用户体验")
                        .font(.body)
                    Text("• 技术支持和故障排除")
                        .font(.body)
                    Text("• 安全保护和防止滥用")
                        .font(.body)
                    Text("• 法律合规要求")
                        .font(.body)
                    
                    Text("3. 信息共享")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们不会向第三方出售、交易或转让您的个人信息，除非：")
                        .font(.body)
                    
                    Text("• 获得您的明确同意")
                        .font(.body)
                    Text("• 法律要求或政府机构要求")
                        .font(.body)
                    Text("• 保护我们的权利和安全")
                        .font(.body)
                    Text("• 与可信赖的服务提供商合作（如 LeanCloud）")
                        .font(.body)
                    
                    Text("4. 数据安全")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 使用 Apple Keychain Services 加密存储敏感信息")
                        .font(.body)
                    Text("• 采用 HTTPS 加密传输数据")
                        .font(.body)
                    Text("• 定期安全审计和更新")
                        .font(.body)
                    Text("• 限制员工访问用户数据")
                        .font(.body)
                    
                    Text("5. 数据保留")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们仅在提供服务所必需的时间内保留您的个人信息。当您删除账户或我们不再需要这些信息时，我们会安全删除或匿名化处理。")
                        .font(.body)
                    
                    Text("6. 您的权利")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 访问和查看您的个人信息")
                        .font(.body)
                    Text("• 更正不准确的信息")
                        .font(.body)
                    Text("• 删除您的账户和数据")
                        .font(.body)
                    Text("• 撤回同意")
                        .font(.body)
                    Text("• 数据可携带性")
                        .font(.body)
                    
                    Text("7. 儿童隐私")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("本应用不面向13岁以下的儿童。我们不会故意收集13岁以下儿童的个人信息。如果您发现我们收集了儿童信息，请立即联系我们。")
                        .font(.body)
                    
                    Text("8. 第三方服务")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们使用以下第三方服务：")
                        .font(.body)
                    Text("• LeanCloud：数据存储和云服务")
                        .font(.body)
                    Text("• Apple Sign In：用户认证")
                        .font(.body)
                    Text("• 这些服务有自己的隐私政策")
                        .font(.body)
                    
                    Text("9. 政策更新")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们可能会不时更新本隐私政策。重大变更时，我们会通过应用内通知或电子邮件通知您。")
                        .font(.body)
                    
                    Text("10. 联系我们")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("如果您对本隐私政策有任何疑问，请通过以下方式联系我们：")
                        .font(.body)
                    Text("• 邮箱：928322941@qq.com")
                        .font(.body)
                    Text("• 应用内反馈")
                        .font(.body)
                    
                    Text("感谢您信任我们保护您的隐私。我们将继续努力为您提供安全、可靠的服务。")
                        .font(.body)
                        .italic()
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("隐私政策")
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

#Preview {
    PrivacyPolicyView()
} 